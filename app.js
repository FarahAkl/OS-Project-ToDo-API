const express = require("express");
const mongoose = require("mongoose");

const app = express();
const PORT = 3000;

// Middleware to parse JSON requests
app.use(express.json());
app.use(express.urlencoded({ extended: true })); // For form data

// Connect to MongoDB
mongoose
  .connect("mongodb://mongo:27017/todo")
  .then(() => {
    console.log("Connected to MongoDB");
  })
  .catch((err) => {
    console.error("MongoDB connection error:", err);
  });

// Define a simple Todo model

const todoSchema = new mongoose.Schema({
  task: String,
  done: Boolean,
});

// Create a model from the schema

const Todo = mongoose.model("Todo", todoSchema);

// get all todos

app.get("/todos", async (req, res) => {
  try {
    const todos = await Todo.find();
    res.status(200).json(todos);
  } catch (err) {
    console.error("Error fetching todos:", err);
    res.status(500).json({ message: err.message });
  }
});

// Add a new toDo task

app.post("/todos", async (req, res) => {
  const { task } = req.body;
  if (!task) {
    return res.status(400).json({ message: "Task is required" });
  }
  try {
    const newTodo = new Todo({ task , done:false });
    await newTodo.save();
    res.status(201).json(newTodo);
  } catch (err) {
    console.error("Error adding todo:", err);
    res.status(500).json({ message: err.message });
  }
});

// Get a specific todo by ID

app.get("/todos/:id", async (req, res) => {
  try {
    const todo = await Todo.findById(req.params.id);
    if (!todo) {
      return res.status(404).json({ message: "Todo not found" });
    }
    res.status(200).json(todo);
  } catch (err) {
    console.error("Error fetching todo:", err);
    res.status(500).json({ message: err.message });
  }
});

// Delete a todo by ID

app.delete("/todos/:id", async (req, res) => {
  try {
    const deletedTodo = await Todo.findByIdAndDelete(req.params.id);
    if (!deletedTodo) {
      return res.status(404).json({ message: "Todo not found" });
    }
    res.status(204).end(); // No content to send back
  } catch (err) {
    console.error("Error deleting todo:", err);
    res.status(500).json({ message: err.message });
  }
});

// update the todo

app.put("/todos/:id",  async (req, res) => {
  try {
    const updatedTodo = await Todo.findByIdAndUpdate(
      req.params.id,
      req.body, 
      { new: true } // Return the updated document
    );

    if (!updatedTodo) {
      return res.status(404).json({ message: "Todo not found" });
    }

    res.status(200).json(updatedTodo);
  } catch (err) {
    console.error("Error updating todo:", err);
    res.status(500).json({ message: err.message });
  }
});

// Start the server

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
