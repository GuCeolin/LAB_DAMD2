const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;
const DATA_FILE = path.join(__dirname, 'tasks.json');

app.use(cors());
app.use(bodyParser.json());

// Helper to read tasks from file
const readTasks = () => {
    if (!fs.existsSync(DATA_FILE)) {
        return [];
    }
    const data = fs.readFileSync(DATA_FILE, 'utf8');
    try {
        return JSON.parse(data);
    } catch (e) {
        return [];
    }
};

// Helper to write tasks to file
const writeTasks = (tasks) => {
    fs.writeFileSync(DATA_FILE, JSON.stringify(tasks, null, 2));
};

// GET /tasks - Get all tasks
app.get('/tasks', (req, res) => {
    const tasks = readTasks();
    res.json(tasks);
});

// POST /tasks - Create a new task
app.post('/tasks', (req, res) => {
    const tasks = readTasks();
    const newTask = req.body;
    
    // Basic validation
    if (!newTask.id || !newTask.title) {
        return res.status(400).json({ error: 'ID and Title are required' });
    }

    // Check if task already exists (idempotency for sync)
    const existingIndex = tasks.findIndex(t => t.id === newTask.id);
    if (existingIndex >= 0) {
        // Update if exists (LWW strategy could be handled here or client, 
        // but for simple create, we might just overwrite or ignore)
        tasks[existingIndex] = newTask;
    } else {
        tasks.push(newTask);
    }
    
    writeTasks(tasks);
    console.log(`Task created/synced: ${newTask.title}`);
    res.status(201).json(newTask);
});

// PUT /tasks/:id - Update a task
app.put('/tasks/:id', (req, res) => {
    const { id } = req.params;
    const updatedTask = req.body;
    let tasks = readTasks();
    
    const index = tasks.findIndex(t => t.id === id);
    if (index === -1) {
        // If task doesn't exist but we are updating, we might want to create it (upsert)
        // depending on sync logic. For now, let's create it.
        tasks.push(updatedTask);
        writeTasks(tasks);
         console.log(`Task updated (upsert): ${updatedTask.title}`);
        return res.json(updatedTask);
    }

    // Last-Write-Wins logic on server side
    const currentTask = tasks[index];
    const incomingTime = new Date(updatedTask.updatedAt).getTime();
    const currentTime = new Date(currentTask.updatedAt).getTime();

    // If incoming is OLDER than current, reject it (Server Wins)
    if (incomingTime < currentTime) {
        console.log(`Conflict: Incoming update for ${id} is older (${updatedTask.updatedAt}) than server (${currentTask.updatedAt}). Ignoring.`);
        return res.status(409).json({ 
            error: 'Conflict: Server has a newer version',
            serverTask: currentTask 
        });
    }

    // Otherwise, Client Wins (incoming is newer or same)
    tasks[index] = updatedTask;
    writeTasks(tasks);
    console.log(`Task updated: ${updatedTask.title}`);
    res.json(updatedTask);
});

// DELETE /tasks/:id - Delete a task
app.delete('/tasks/:id', (req, res) => {
    const { id } = req.params;
    let tasks = readTasks();
    
    const newTasks = tasks.filter(t => t.id !== id);
    writeTasks(newTasks);
    console.log(`Task deleted: ${id}`);
    res.status(204).send(); // No content
});

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
