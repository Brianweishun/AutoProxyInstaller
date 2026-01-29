const express = require('express');
const session = require('express-session');
const bodyParser = require('body-parser');
const { exec } = require("child_process");
const path = require('path');
const apiRouter = require('./routes/api.js');
const fs = require('fs');

const app = express();

// 1. Session 設定
app.use(session({
    secret: 'borgen-api-secret-key',
    resave: false,
    saveUninitialized: true,
    cookie: { maxAge: 600000 } // 10 分鐘後過期
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- 登入驗證中間件 ---
const authMiddleware = (req, res, next) => {
    if (req.session.loggedIn) {
        next(); // 已登入，繼續執行
    } else {
        res.redirect('/login.html'); // 未登入，強制導向登入頁
    }
};

// 2. 登入邏輯路由
app.post('/auth/login', (req, res) => {
    const { username, password } = req.body;
    // 這裡設定你的管理員帳密
    if (username === 'admin' && password === 'admin') {
        req.session.loggedIn = true;
		req.session.username = username; // 儲存動態名稱
        res.redirect('/'); 
    } else {
        res.send('Wrong username or password  <a href="/login.html">Re-login</a>');
    }
});

// 新增一個 API 讓前端獲取目前使用者資訊
app.get('/api/me', (req, res) => {
    if (req.session.loggedIn) {
        res.json({ username: req.session.username }); // 回傳 Session 裡的名稱
    } else {
        res.status(401).json({ error: 'Not login' });
    }
});

// 3. 公開資源 (登入頁與樣式)
app.use(express.static(path.join(__dirname, 'public')));

// 4. 首頁路由 (受保護：登入後才開啟 index.html)
app.get('/', authMiddleware, (req, res) => {
    res.sendFile(path.join(__dirname, 'private/index.html'));
});

// 5. 受保護的靜態資源 (登入後才能存取 private 裡的 main.js)
app.use('/private', authMiddleware, express.static(path.join(__dirname, 'private')));

// 6. API 路由 (同樣加上驗證，防止有人繞過前端直接打 API)
app.use('/api', authMiddleware, apiRouter);

// 新增登出路由
app.get('/logout', (req, res) => {
    req.session.destroy((err) => {
        if (err) {
            console.log(err);
        }
        res.redirect('/login.html'); // 清除後導向登入頁
    });
});

app.get('/api/folders', (req, res) => {
	const prefix = req.query.prefix || '';
    const targetPath = path.join(__dirname, 'keypasco'); // 你要掃描的特定路徑

	// console.log("正在掃描路徑:", targetPath);

    try {
		if (!fs.existsSync(targetPath)) {
            // console.error("錯誤：找不到資料夾");
            return res.status(404).json({ error: '資料夾不存在' });
        }
        // 讀取該目錄下所有內容
        const files = fs.readdirSync(targetPath);
        
        // 過濾：必須是資料夾，且名稱以 'KeypascoProxyInstall' 開頭
        const filteredFolders = files.filter(file => {
            const fullPath = path.join(targetPath, file);
			const isDir = fs.statSync(fullPath).isDirectory();
            return isDir && file.startsWith(prefix);
        });

        res.json(filteredFolders);
    } catch (err) {
		// console.error("後端發生錯誤:", err);
        res.status(500).json({ error: '無法讀取資料夾' });
    }
});

app.get('/api/list', (req, res) => {
    const prefix = req.query.prefix || '';
    const type = req.query.type || 'all'; // dir, file, 或 all
    const targetPath = path.join(__dirname, 'keypasco');

    try {
        if (!fs.existsSync(targetPath)) return res.status(404).json({ error: '路徑不存在' });

        const items = fs.readdirSync(targetPath);
        
        const filtered = items.filter(item => {
            const fullPath = path.join(targetPath, item);
            const stats = fs.statSync(fullPath);
            const isMatch = item.startsWith(prefix);

            if (type === 'dir') return isMatch && stats.isDirectory();
            if (type === 'file') return isMatch && stats.isFile();
            return isMatch;
        });

        res.json(filtered);
    } catch (err) {
        res.status(500).json({ error: '讀取失敗' });
    }
});

const port = 3000;
app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});
