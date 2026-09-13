AI TASK PLANNER AGENT:

Modified a basic AI chatbot to an agent that plans out a schedule for a user given a list of tasks,
a timeframe, and a set of notes detailing importance of tasks for prioritization. We modified both models to utilize two versions of Qwen.

For the assignment's extra credit, and in order to make the application testable, as Github can only test locally run models, we did the following: first, we moved both the local and remote responses out of the main function to plan the schedule. Then, we encapsulated the remote call in a Try-Except block. Next, we used an info box to notify that a response is generating and a warning box that displays text indicating that a local model is being used and why. For manual testing, we kept the checkbox for "use local model" and simply made the option raise an exception in the try-except block.