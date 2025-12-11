const express = require('express');
const app = express();
const { exec } = require("child_process");
const path = require('path');
const apiRouter = require('./routes/api.js');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 前端頁面
app.use(express.static(path.join(__dirname, 'public')));

// API 路由
app.use('/api', apiRouter);

const port = 3000;
app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});
