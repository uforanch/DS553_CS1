import gradio as gr
import spaces
from huggingface_hub import InferenceClient
from transformers import pipeline

LOCAL_MODEL = "Qwen/Qwen3-0.6B"
REMOTE_MODEL = "deepseek-ai/DeepSeek-V4-Flash-0731"

DEFAULT_SYSTEM_MESSAGE = """You are a Expert daily planning assistant.\
    Given a list of tasks and the time window the user has avaailable build a realistic, well-ordered and planned schedule\
        
        For all tasks, descide:
        1. When during the day the task should take place.
        2. The level of focus and effort that is demanded.
        3. a Start and end time.
        
        If a task is not able to fit within the associated time window suggest a new option or ask the user what is of least importance."""


pipe = pipeline(
    "text-generation",
    model=LOCAL_MODEL,
    dtype="auto",
    device="cuda",
)

fancy_css = """
.gradio-container {
    width: 96% !important;
    max-width: none !important;
}
#app-title {
    text-align: center;
    margin-bottom: 4px;
}
#app-subtitle {
    text-align: center;
    color: var(--body-text-color-subdued);
    margin-bottom: 24px;
}
#chat-container {
    width: 100%;
    border: 1px solid var(--border-color-primary);
    border-radius: 12px;
    padding: 16px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}
#model-note {
    font-size: 0.9em;
    color: var(--body-text-color-subdued);
    margin-top: 8px;
}
@media (max-width: 768px) {
    .gradio-container {
        width: 98% !important;
    }
    #chat-container {
        padding: 8px;
    }
}
"""

def build_planning_prompt(tasks_text, start_time, end_time, notes):
    notes = notes.strip() if notes else "None"
    return f"""My Available time today is from {start_time} to {end_time}.
    
The tasks I need to complete today\
{tasks_text.strip()}

Additional Notes {notes}

Build my schedule for today
"""



@spaces.GPU
def local_generate(
    messages,
    max_tokens,
    temperature,
    top_p,
):
    outputs = pipe(
        messages,
        max_new_tokens=max_tokens,
        do_sample=True,
        temperature=temperature,
        top_p=top_p,
    )

    return outputs[0]["generated_text"][-1]["content"]


def plan_schedule(
    tasks_text,
    start_time,
    end_time,
    notes,
    system_message,
    max_tokens,
    temperature,
    top_p,
    use_local_model,
    hf_token: gr.OAuthToken,
):
    if not tasks_text or not tasks_text.strip():
        yield " Please Enter a task you want to complete today"
        return
    if not start_time or not start_time.strip() or not end_time or not end_time.strip():
        yield " Please input both a start and end time for your day"

    messages = [{"role": "system", "content": system_message},
                {
                    "role": "user",
                    "content":build_planning_prompt(tasks_text, start_time, end_time, notes),
                },
            ]


    if use_local_model:
        print("[MODE] local")

        response = local_generate(
            messages,
            max_tokens,
            temperature,
            top_p,
        )

        yield response
        return

    print("[MODE] api")

    if hf_token is None or not getattr(hf_token, "token", None):
        yield "⚠️ Please log in with your Hugging Face account first."
        return

    client = InferenceClient(
        token=hf_token.token,
        model=REMOTE_MODEL,
    )

    response = ""

    for chunk in client.chat_completion(
        messages,
        max_tokens=max_tokens,
        stream=True,
        temperature=temperature,
        top_p=top_p,
    ):
        choices = chunk.choices
        token = ""

        if len(choices) and choices[0].delta.content:
            token = choices[0].delta.content

        response += token
        yield response


with gr.Blocks(css=fancy_css) as demo:
    with gr.Sidebar():
        gr.LoginButton()

    gr.Markdown(
        "# AI Task Planner",
        elem_id="app-title",
    )

    gr.Markdown(
        "List the tasks you want to complete today and get a ordered schedule to help you complete them!",
        elem_id="app-subtitle",
    )


# AI Generated code from Claude Code. - Stephen Prompt: 
    with gr.Column(elem_id="chat-container"):
        with gr.Row():
            with gr.Column(scale=1):
                tasks_input = gr.Textbox(
                    label="Todays Tasks",
                    placeholder=(
                        "Class Project\n"
                        "Gym\n"
                        "Groccery Shopping\n"
                    ),
                    lines=8,
                )
                with gr.Row():
                 start_time_input = gr.Textbox(
                    label="Day starts at",
                    value="9:00 AM",
                    )
                end_time_input = gr.Textbox(
                        label="Day ends at",
                        value="6:00 PM",)
                notes_input = gr.Textbox(
                        label="Notes / priorities (optional)",
                        placeholder="e.g. essay is due tomorrow, I'm most focused in the morning, need a lunch break",
                        lines=2,
                )

                with gr.Accordion("Advanced settings", open=False):
                    system_message_input = gr.Textbox(
                        value=DEFAULT_SYSTEM_MESSAGE,
                        label="System message",
                        lines=6,
                    )
                    max_tokens_input = gr.Slider(
                        minimum=1,
                        maximum=2048,
                        value=768,
                        step=1,
                        label="Max new tokens",
                    )
                    temperature_input = gr.Slider(
                        minimum=0.1,
                        maximum=2.0,
                        value=0.7,
                        step=0.1,
                        label="Temperature",
                    )
                    top_p_input = gr.Slider(
                        minimum=0.1,
                        maximum=1.0,
                        value=0.95,
                        step=0.05,
                        label="Top-p (nucleus sampling)",
                    )
                    use_local_model_input = gr.Checkbox(
                        label="Use Local Model",
                        value=False,
                        )

                generate_button = gr.Button("📅 Generate My Plan", variant="primary")

            with gr.Column(scale=1):
                plan_output = gr.Markdown(label="Your schedule")

        gr.Markdown(
            "Use **Advanced settings** to switch between the API model and the "
            "locally executed model, or to tweak generation settings.",
            elem_id="model-note",
        )

    generate_button.click(
        fn=plan_schedule,
        inputs=[
            tasks_input,
            start_time_input,
            end_time_input,
            notes_input,
            system_message_input,
            max_tokens_input,
            temperature_input,
            top_p_input,
            use_local_model_input,
        ],
        outputs=plan_output,
    )



if __name__ == "__main__":
    demo.launch()
