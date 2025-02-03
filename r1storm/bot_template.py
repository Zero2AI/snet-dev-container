# Initial setup and configurations
INITIAL_MSG = "Welcome to Our Multimodal Chatbot, Start interacting below to experience its capabilities!"
# agent_prompt = TMP_ASSISTANT_PROMPT
APP_NAME = "DeepSeek-R1 Assistant"
agent_name = APP_NAME
agent_desc = "A helpful AI assistant powered by DeepSeek-R1"
agent_example = "User: What's the capital of France?&Assistant: The capital of France is Paris."
split_examples = [[part] for part in agent_example.split('&')]


import replicate
import gradio as gr
from dotenv import load_dotenv
import os

load_dotenv()

REPLICATE_API_TOKEN = os.getenv("REPLICATE_API_TOKEN")

def process_message(history, user_input):
    system_message = "You are a helpful assistant."
    prompt = f"{system_message}\n\n{user_input}"
    
    buffer = ""
    in_think = False
    think_content = []
    final_answer = []
    
    new_history = history + [(user_input, "")]
    yield new_history, "", ""
    
    # Start streaming from Replicate
    stream = replicate.stream(
        "deepseek-ai/deepseek-r1",
        input={
            "top_p": 1,
            "prompt": prompt,
            "max_tokens": 20480,
            "temperature": 0.7,
            "presence_penalty": 0,
            "frequency_penalty": 0,
        },
    )

    thinking_placeholder = " ...[Thinking]...\n See the thought process below:"
    
    for event in stream:
        buffer += str(event)
        
        while True:
            # 1) Not in think mode, check if we see a <think> tag
            if not in_think and '<think>' in buffer:
                parts = buffer.split('<think>', 1)
                before_think = parts[0]
                buffer = parts[1] if len(parts) > 1 else ""
                
                # Append the text before <think> to the visible answer
                if before_think:
                    final_answer.append(before_think)
                
                # Show "thinking..." in the chatbot
                final_answer.append(thinking_placeholder)
                new_history[-1] = (user_input, "".join(final_answer))
                yield new_history, "\n".join(think_content), ""
                
                # Remove the placeholder from the final answer so it doesn't
                # show up permanently (we only want it visible while in_think)
                final_answer.pop()
                
                in_think = True
            
            # 2) Already in think mode, check if we see a </think> tag
            elif in_think and '</think>' in buffer:
                parts = buffer.split('</think>', 1)
                think_part = parts[0]
                buffer = parts[1] if len(parts) > 1 else ""
                
                # Accumulate the "thinking" text
                think_content.append(think_part)
                
                # Update the 'thought process' panel in real-time
                yield new_history, "\n".join(think_content), ""
                
                # We just finished thinking; exit 'in_think' mode
                in_think = False
            
            else:
                # If no more <think> or </think> tags are found in `buffer`,
                # break out of this while-loop to wait for next chunk
                break
        
        # 3) Anything outside of <think> ... </think> is appended to final_answer
        #    If we're still in "thinking" mode, we won't show new text in the chatbot,
        #    but if we've exited the think block, we do.
        if not in_think and buffer:
            final_answer.append(buffer)
            new_history[-1] = (user_input, "".join(final_answer))
            yield new_history, "\n".join(think_content), ""
            buffer = ""
    
    # Final cleanup (when the stream ends)
    if buffer:
        if in_think:
            # If the stream ended and we are still in think mode,
            # we add that leftover to think_content
            think_content.append(buffer)
        else:
            final_answer.append(buffer)
        new_history[-1] = (user_input, "".join(final_answer))
        yield new_history, "\n".join(think_content), ""
    
    return new_history, "\n".join(think_content), ""

with gr.Blocks(title="DeepSeek") as demo:
    gr.Markdown("# 🧠 DeepSeek-R1")
    
    with gr.Row():
        chatbot = gr.Chatbot(height=400)
        
    with gr.Row():
        msg = gr.Textbox(label="Your message", placeholder="Type in...")
        
    with gr.Accordion("Show thought process", open=False):
        think_display = gr.Markdown()
    
    clear = gr.ClearButton([msg, chatbot, think_display])
    
    msg.submit(
        process_message,
        [chatbot, msg],
        [chatbot, think_display, msg],
        show_progress="full",
    )

if __name__ == "__main__":
    demo.launch(server_name="0.0.0.0", server_port=7860)
