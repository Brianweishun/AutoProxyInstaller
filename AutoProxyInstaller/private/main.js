// 封裝統一的請求工具
async function borgenFetch(url, options = {}) {
    const response = await fetch(url, options);

    // 統一攔截 401 (未授權/Session過期) 或 403 (被禁止)
    if (response.status === 401 || response.status === 403) {
        alert("連線逾時或權限不足，請重新登入");
        window.location.href = "/login.html";
        return null; // 停止後續執行
    }

    return response;
}

async function initUserInfo() {
    try {
        // 使用我們之前封裝的 borgenFetch
        const response = await borgenFetch("/api/me");
        if (!response) return;

        const data = await response.json();
        // 將名稱填入 HTML 標籤
        document.getElementById("current-user").textContent = data.username;
    } catch (err) {
        console.error("無法獲取使用者資訊", err);
    }
}

// 確保網頁載入完成後執行
window.addEventListener('DOMContentLoaded', initUserInfo);

function addLog(msg) {
    const log = document.getElementById("log");
    log.textContent += msg + "\n";
    log.scrollTop = log.scrollHeight;
}

async function createICP() {
    console.log("Create ICP");
    const saUsername = document.getElementById("saUsername").value;
    const saPassword = document.getElementById("saPassword").value;
    const server = document.getElementById("apiServer").value;
    const icp = document.getElementById("icp").value;
    const fullname = document.getElementById("fullname").value;
     
    addLog("📤 [Client] Sending request…");

    const payload = {
        server,        // connect server
        saUsername,
        saPassword,
        icp,            // icp
        fullname        //full name
    };

    try {
        const response = await borgenFetch("/api/create-icp", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
        });

        const result = await response.json();
        document.getElementById("result").textContent =
            JSON.stringify(result, null, 4);

        addLog("✔ [Server] Response received");
        addLog(JSON.stringify(result, null, 2));

    } catch (err) {
        addLog("❌ Error: " + err.message);
    }
}

async function addBorgenUser() {
    console.log("Add Borgen User");
    const saUsername = document.getElementById("saUsername").value;
    const saPassword = document.getElementById("saPassword").value;
    const server = document.getElementById("apiServer").value;
    const icp = document.getElementById("icp").value;
    const borgenUser = document.getElementById("brogenUser").value;
    const borgenPassword = document.getElementById("borgenPassword").value;
	const checkedRoles = Array.from(document.querySelectorAll('input[name="roles"]:checked'))
                              .map(cb => cb.value);

    addLog("📤 [Client] Sending request…");

    const payload = {
        server,        // connect server
        saUsername,
        saPassword,
        icp,
        borgenUser,
        borgenPassword,
		roles: checkedRoles
    };

    try {
        const response = await borgenFetch("/api/create-borgen-user", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
        });

        const result = await response.json();
        document.getElementById("result").textContent =
            JSON.stringify(result, null, 4);

        addLog("✔ [Server] Response received");
        addLog(JSON.stringify(result, null, 2));

    } catch (err) {
        addLog("❌ Error: " + err.message);
    }
}

async function downloadP12() {
    console.log("download P12");
    const saUsername = document.getElementById("saUsername").value;
    const saPassword = document.getElementById("saPassword").value;
    const server = document.getElementById("apiServer").value;
    const icp = document.getElementById("icp").value;
    const user = document.getElementById("user").value;
    const password = document.getElementById("password").value;

    if (!user.includes("|")) {
        user = icp + "|" + user;
    }

    addLog("📤 [Client] Sending request…");

    const payload = {
        server,        // connect server
        saUsername,
        saPassword,
        icp,
        user,
        password
    };

    try {
        const response = await borgenFetch("/api/download-p12", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
        });

        const result = await response.json();
        document.getElementById("result").textContent =
            JSON.stringify(result, null, 4);

        addLog("✔ [Server] Response received");
        addLog(JSON.stringify(result, null, 2));

    } catch (err) {
        addLog("❌ Error: " + err.message);
    }
}


async function runPs1() {
    console.log("run ps1");

    try {
        const response = await borgenFetch("/api/run-ps", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
        });

        const result = await response.json();
        document.getElementById("result").textContent =
            JSON.stringify(result, null, 4);

        addLog("✔ [Server] Response received");
        addLog(JSON.stringify(result, null, 2));

    } catch (err) {
        addLog("❌ Error: " + err.message);
    }
}

async function downloadInstaller() {
    console.log("download");
    
    const icp = document.getElementById("icp").value;
    const requestUrl  = "/api/download?icp=" + icp;
    try {
        const response = await borgenFetch(requestUrl , {
            method: "GET",
            headers: { "Content-Type": "application/json" },
        });

        if (!response.ok) {
            const errData = await response.json();
            addLog("❌ Error: " + errData.error);
            return;
        }


        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);

        const a = document.createElement("a");
        a.href = url;
        a.download = "ProxyInstaller.exe"; // filename for user
        document.body.appendChild(a);
        a.click();
        a.remove();

        addLog("✔ [Server] File download triggered");

    } catch (err) {
        addLog("❌ Error: " + err.message);
    }
}

async function downloadP12File() {
    console.log("downloadP12File");
    
    const user = document.getElementById("user").value;
    const requestUrl  = "/api/downloadP12File?user=" + user;

	const filename = user.replace("|","_");
	
    try {
        const response = await borgenFetch(requestUrl , {
            method: "GET",
            headers: { "Content-Type": "application/json" },
        });

        if (!response.ok) {
            const errData = await response.json();
            addLog("❌ Error: " + errData.error);
            return;
        }


        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);

        const a = document.createElement("a");
        a.href = url;
        a.download = filename + ".p12"; // filename for user
        document.body.appendChild(a);
        a.click();
        a.remove();

        addLog("✔ [Server] File download triggered");

    } catch (err) {
        addLog("❌ Error: " + err.message);
    }
}


document.getElementById("btnCreateICP").addEventListener("click", createICP);
document.getElementById("btnAddBorgenUser").addEventListener("click", addBorgenUser);
document.getElementById("btnDownloadP12").addEventListener("click", downloadP12);
document.getElementById("btnRunPS").addEventListener("click", runPs1);
document.getElementById("btnDownloadInstaller").addEventListener("click", downloadInstaller);
document.getElementById("btnDownloadP12File").addEventListener("click", downloadP12File);