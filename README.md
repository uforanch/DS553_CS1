---
title: DS553 Fall26
emoji: 💬
colorFrom: yellow
colorTo: purple
sdk: gradio
sdk_version: 6.5.1
app_file: app.py
pinned: false
hf_oauth: true
hf_oauth_scopes:
  - inference-api
license: mit
---

An example chatbot using [Gradio](https://gradio.app), [`huggingface_hub`](https://huggingface.co/docs/huggingface_hub/v0.22.2/en/index), and the [Hugging Face Inference API](https://huggingface.co/docs/api-inference/index)



AI TASK PLANNER AGENT:

Modified a basic AI chatbot to an agent that plans out a schedule for a user given a list of tasks,
a timeframe, and a set of notes detailing importance of tasks for prioritization. We modified both models to utilize two versions of Qwen.

For the assignment's extra credit, and in order to make the application testable, as Github can only test locally run models, we did the following: first, we moved both the local and remote responses out of the main function to plan the schedule. Then, we encapsulated the remote call in a Try-Except block. Next, we used an info box to notify that a response is generating and a warning box that displays text indicating that a local model is being used and why. For manual testing, we kept the checkbox for "use local model" and simply made the option raise an exception in the try-except block.