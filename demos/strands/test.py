from strands import Agent, tool
from strands_tools import calculator, current_time

# Define a custom tool
@tool
def letter_counter(word: str, letter: str) -> int:
    """Count occurrences of a specific letter in a word."""
    if not isinstance(word, str) or not isinstance(letter, str):
        return 0
    if len(letter) != 1:
        raise ValueError("The 'letter' parameter must be a single character")
    return word.lower().count(letter.lower())

# Create agent with tools
agent = Agent(tools=[calculator, current_time, letter_counter])

# Use the agent
message = """
I have 3 requests:
1. What is the time right now?
2. Calculate 3111696 / 74088
3. Tell me how many letter R's are in the word "strawberry"
"""

result = agent(message)
print(result.message)
