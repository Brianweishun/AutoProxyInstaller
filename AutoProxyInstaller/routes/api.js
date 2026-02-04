// api.js

const express = require('express');
const router = express.Router();
const fetch = (...args) =>
    import('node-fetch').then(({ default: fetch }) => fetch(...args));

const fs = require('fs');
const path = require('path');
const { exec } = require("child_process");


router.post('/create-icp', async (req, res) => {

    const server = req.body.server;      // input API Server
    const saUsername = req.body.saUsername;
    const saPassword = req.body.saPassword;
    const icp = req.body.icp;      // input ICP
    const fullname = req.body.fullname;      // input Full name

    const url = server + "/admin/api/sysadmin/icps";

    const payload = {
        id: icp,
        fullname: fullname,
    };

    const username = saUsername;
    const password = saPassword;
    const auth = Buffer.from(`${username}:${password}`).toString('base64');

    try {
        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Authorization": "Basic " + auth,
                "Content-Type": "application/json;version=1"
            },
            body: JSON.stringify(payload),
            redirect: "follow"
        });

        const text = await response.text();
        let data;
        try {
            data = JSON.parse(text);
        } catch {
            data = { message: text };
        }

        res.json(data);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


router.post('/create-borgen-user', async (req, res) => {
    const server = req.body.server;      // input API Server
    const saUsername = req.body.saUsername;
    const saPassword = req.body.saPassword;
    const icp = req.body.icp;      // input ICP
    const url = server + "/admin/api/sysadmin/icps/" + icp + "/borgenusers";
    const borgenUserName = req.body.borgenUser;
    const borgenPassword = req.body.borgenPassword;
	const roles = req.body.roles;
    
    const payload = {
        username: borgenUserName,
        password: borgenPassword,
		roles:roles || []
        // roles: [
        //     "ROLE_BILLING",
        //     "ROLE_BORGEN_USER_EVENTS",
        //     "ROLE_CLIENT_API",
        //     "ROLE_CUSTOMER_API",
        //     "ROLE_END_USER_EVENTS",
        //     "ROLE_END_USER_SUPPORT",
        //     "ROLE_ICP_ADMIN",
        //     "ROLE_ICP_STATISTICS"
        // ]
    };

    const username = saUsername;
    const password = saPassword;
    const auth = Buffer.from(`${username}:${password}`).toString('base64');

    try {
        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Authorization": "Basic " + auth,
                "Content-Type": "application/json;version=1"
            },
            body: JSON.stringify(payload),
            redirect: "follow"
        });

        const text = await response.text();
        let result;
        try {
            result = JSON.parse(text);
        } catch {
            result = { message: text };
        }

		const logContent = [``,
			`Server: ${server}`,
			`ICP: ${icp}`,
			`Username: ${borgenUserName}`,
			`P12 Password: ${borgenPassword}`
		].join('\n'); // 使用 join('\n') 確保每一項都換行且沒有前方空格
		recordCredential(icp, logContent);

        res.json(result);

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.post('/download-p12', async (req, res) => {
    const server = req.body.server;      // input API Server
    const saUsername = req.body.saUsername;
    const saPassword = req.body.saPassword;
    const icp = req.body.icp;      // input ICP
    const url = server + "/admin/api/sysadmin/icps/" + icp + "/certificates/main";
    const user = req.body.user;
    const p12Password = req.body.password;
    
    const payload = {
        "commonName": user,
        "password": p12Password,
        "roles": [
            "ROLE_ICP_STATISTICS",
            "ROLE_CUSTOMER_API",
            "ROLE_END_USER_EVENTS",
            "ROLE_END_USER_SUPPORT"
        ],
        "validityPeriodInYears": 10
    };

    const username = saUsername;
    const password = saPassword;
    const auth = Buffer.from(`${username}:${password}`).toString('base64');

    try {
        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Authorization": "Basic " + auth,
                "Content-Type": "application/json;version=1"
            },
            body: JSON.stringify(payload),
            redirect: "follow"
        });

        
        if (!response.ok) {
			// recordCredential(icp,`[Failed]Created Borgen User:
            // Server: ${server}
            // ICP: ${icp}
            // Username: ${user}
            // Password: ${p12Password}`);
            throw new Error(`API error: ${response.status}`);
        }

        // 取得二進位資料
        const buffer = await response.arrayBuffer();
        const filename = user.replace("|","_");
        const filePath = path.join(__dirname, 'certs', `${filename}.p12`);

        // 確保資料夾存在
        fs.mkdirSync(path.dirname(filePath), { recursive: true });

        // 寫入檔案
        fs.writeFileSync(filePath, Buffer.from(buffer));

		// recordCredential(icp, `[Success]Created Borgen User:
        //     Server: ${server}
        //     ICP: ${icp}
        //     Username: ${user}
        //     Password: ${p12Password}`);

        // 回傳下載連結
        res.json({ message: 'File downloaded', file: `/certs/${filename}.p12` });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


router.post('/run-ps', async (req, res) => {
    // const scriptPath = path.join(process.cwd(), "keypasco", "myscript.ps1");; // Web 根目錄
    const scriptPath = path.join(process.cwd(), "keypasco", "GenerateInstallV1.ps1"); // Web 根目錄
    const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}"  -CertName "test3_icpadmin" -CertPassword "Keypasco168"`;

    exec(command, (error, stdout, stderr) => {
        return res.json({
            success: !error,
            command: command,
            // stdout: stdout,
            // stderr: stderr,
            error: error ? error.message : null
        });
        if (error) {
            return res.json({ error: error.message });
        }
        if (stderr) {
            return res.json({ error: stderr });
        }
        res.json({ output: stdout });
    });
});

router.get('/download', async (req, res) => {
    const icp = req.query.icp;
    const filePath = path.join(__dirname, "../keypasco/" + icp + "/ProxyInstaller.exe"); // replace with your file
    
    if (!fs.existsSync(filePath)) {
        console.error("File not found:", filePath);
        return res.status(404).json({ error: "Installer not found for icp=" + icp });
    }

    res.download(filePath, "ProxyInstaller.exe", (err) => {
        if (err) {
            console.error("Error downloading file:", err);
            res.status(500).send("Error downloading file");
        }
    });
});

router.get('/downloadP12File', async (req, res) => {
    const user = req.query.user;
	const filename = user.replace("|","_");
	const filePath = path.join(__dirname, "./certs/" + filename + ".p12"); // replace with your file

	
    if (!fs.existsSync(filePath)) {
        console.error("File not found:", filePath);
        return res.status(404).json({ error: "Installer not found for icp=" + icp });
    }

    res.download(filePath, filename + ".p12", (err) => {
        if (err) {
            console.error("Error downloading file:", err);
            res.status(500).send("Error downloading file");
        }
    });
});

// 建立一個統一的紀錄函式
const recordCredential = (subFolder, info) => {
    const baseDir = path.join(__dirname, '../keypasco');
	const targetDir = path.join(baseDir, subFolder);

	// 2. 確保資料夾存在
    if (!fs.existsSync(targetDir)) {
        fs.mkdirSync(targetDir, { recursive: true });
    }

	const filePath = path.join(targetDir, 'credential.txt');
	// const filePath = path.join(__dirname, 'credential.txt');
    const timestamp = new Date().toLocaleString('en-US');
    const content = `[${timestamp}] ${info}\n------------------------\n`;
    
    // 使用 appendFile 確保內容是累加的，不會覆蓋舊紀錄
    fs.appendFileSync(filePath, content, 'utf8');
};

module.exports = router;