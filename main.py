import time
import os
from google import genai
from google.genai import types, errors

# 1. SETUP - Use an environment variable for security!
# Run this in your terminal first: setx GEMINI_API_KEY "your_key_here"
API_KEY = "GEMINI API_KEY" # Paste your key inside the quotes
client = genai.Client(api_key=API_KEY)

# 2. STATE MANAGEMENT - This is your 'Memory'
# We store the full Content objects so we can pass back thought_signatures
history = []

def smart_generate(prompt, model_id="gemini-3-pro-preview", retries=7):
    global history
    delay = 15  # Increased start delay for 503s
    
    user_content = types.Content(role="user", parts=[types.Part.from_text(text=prompt)])
    
    for i in range(retries):
        try:
            print(f"📡 Attempting {model_id}... (Attempt {i+1})")
            config = types.GenerateContentConfig(
                thinking_config=types.ThinkingConfig(thinking_level="HIGH")
            )
            
            response = client.models.generate_content(
                model=model_id, contents=history + [user_content], config=config
            )
            
            history.append(user_content)
            history.append(response.candidates[0].content)
            return response.text

        # UPDATE: Catch BOTH Client and Server errors (429 and 503)
        except (errors.ClientError, errors.ServerError) as e:
            if "429" in str(e) or "503" in str(e):
                err_type = "Throttled" if "429" in str(e) else "Overloaded"
                print(f"⚠️ {err_type}. Waiting {delay}s... (Wait is worth the $50k)")
                time.sleep(delay)
                delay *= 2 
                
                # Switch to Flash if Pro is consistently failing
                if model_id == "gemini-3-pro-preview" and i >= 1:
                    print("🔄 Swapping to FLASH to bypass server congestion.")
                    model_id = "gemini-3-flash-preview"
            else:
                raise e
    
    raise Exception("❌ Global Congestion too high. Take a 10-min break and try again.")

# --- THE 2-DAY SPRINT LOOP ---

# TASK 1: THE CELL (Execute this now)
grid_prompt = """
Generate a Verilog module 'TopGrid'.
1. Instantiate 4 'SwarmNode' modules (node_00, node_01, node_10, node_11) in a 2x2 mesh.
2. Implement XY Routing: Data enters node_00. If node_00.stress_reg > 200, 
   it must assert a 'BACKPRESSURE' signal.
3. When BACKPRESSURE is high, node_00 must stop accepting data and 'reroute' 
   the incoming spike to node_01 or node_10.
4. Add a global 'fault_inject' signal that manually forces node_00 into high-stress mode 
   to test the system's resilience.
"""

current_task = grid_prompt  # Switch to test_prompt for Phase 3
filename = "TopGrid.v"       # Switch to "SystemLevel_tb.v" for Phase 3

print(f"🧬 Phase: {filename}...")
verilog_code = smart_generate(current_task)

with open(filename, "w") as f:
    f.write(verilog_code)

print(f"✅ {filename} created. Use 'iverilog -o sim.vvp TopGrid.v SwarmNode.v {filename}' to test.")