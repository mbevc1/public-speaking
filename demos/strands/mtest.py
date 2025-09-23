from strands import Agent
from strands.models.bedrock import BedrockModel
from strands_tools import calculator, handoff_to_user

system_prompt = """
You are a helpful math tutor for K-12 students. 
Use the calculator tool to help with math problems. 
Do not give the student the answer directly but try to guide them through the problem. 
Hand off to the user for clarification or if you want them to do the calculation themselves. 
"""

provider = BedrockModel(
  region_name="eu-west-1",
  model_id="eu.anthropic.claude-sonnet-4-20250514-v1:0",
  streaming=True,
)

agent = Agent(
  tools=[calculator, handoff_to_user],
  model=provider,
  system_prompt=system_prompt
)

while True:
  question = input("Ask a math question (or type 'exit' to quit): ")
  if question.lower() == 'exit': break
  response = agent(question)
  print(response)
