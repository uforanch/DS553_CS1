from app import local_generate

def test_render():
    messages = [{"role": "system", "content": "You are a friendly chatbot"},
                {"role": "user", "content": "give any response"}]
    assert local_generate(messages, 512, .7, .95)
