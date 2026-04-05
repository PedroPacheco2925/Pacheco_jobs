// Variáveis Globais
let currentJobName = "";
let userLevel = 1;
let jobTools = [];
let jobTasks = [];
let jobVehicles = [];
let playerStats = { totalItems: 0, totalTasks: 0 }; 
let claimedTasksLocal = [];

// --- FUNÇÕES DE NAVEGAÇÃO (Declaradas antes para evitar o erro) ---

function showView(view) {
    // Esconde todas as vistas primeiro
    $("#dashboard-view, #leaderboard-view, #tools-view, #tasks-view, #vehicles-view").hide();

    if (view === "dashboard") {
        $("#dashboard-view").show();
        $("#section-title").text("OVERVIEW");
    } else if (view === "leaderboard") {
        $("#leaderboard-view").show();
        $("#section-title").text("RANKING TOP 10");
        fetchLeaderboard();
    } else if (view === "tools") {
        $("#tools-view").show();
        $("#section-title").text("LOJA DE EQUIPAMENTO");
        renderTools();
    } else if (view === "tasks") {
        $("#tasks-view").show();
        $("#section-title").text("PROGRESSÃO E MISSÕES");
        renderTasks();
    } else if (view === "vehicles") {
        $("#vehicles-view").show();
        $("#section-title").text("GARAGEM DA EMPRESA");
        renderVehicles();
    }
}

// --- RECEBER MENSAGENS DO LUA ---

window.addEventListener('message', function(event) {
    let data = event.data;

    if (data.action === "openTablet") {
        $("#tablet-container").fadeIn(500);
        currentJobName = data.jobName;
        const d = data.data;
        const cfg = data.config;

        // Guardar dados globais
        userLevel = d.level || 1;
        jobTools = cfg.Tools || [];
        jobTasks = cfg.Tasks || [];
        jobVehicles = cfg.Vehicles || [];
        playerStats.totalItems = d.totalItems || 0;
        playerStats.totalTasks = d.totalTasks || 0;

        // Atualizar Textos do Header
        $("#brand-title").text(cfg.JobTitle);
        $("#brand-subtitle").text(cfg.JobSubtitle);
        $("#user-role").text(cfg.RoleName);
        $("#brand-icon").attr("class", cfg.BrandIcon + " logo-icon");

        // Perfil do Jogador
        $("#user-name").text(d.name);
        $("#stat-earned").text(d.totalEarned || 0);
        $("#stat-xp").text(d.xp || 0);
        $("#stat-points").text(d.skillsPoints || 0);
        $("#user-level").text(userLevel);

        // Atualizar Stats do Dashboard
        $("#custom-val-1").text(playerStats.totalItems);
        $("#custom-val-2").text(playerStats.totalTasks);
        $("#custom-val-3").text(0);

        // Resetar Menu Lateral
        $(".nav-item").removeClass("active");
        $('.nav-item[data-target="dashboard"]').addClass("active");
        
        // Chamar a vista inicial
        showView("dashboard");
    }
});

// --- CLIQUE NO MENU LATERAL ---

$(document).on('click', '.nav-item', function() {
    const target = $(this).data("target");
    if (!target) return;
    
    $(".nav-item").removeClass("active");
    $(this).addClass("active");

    showView(target);
});

// --- RENDERIZAÇÃO DE CONTEÚDO ---

function renderTools() {
    $("#tools-list").empty();
    jobTools.forEach(tool => {
        const locked = userLevel < tool.level;
        $("#tools-list").append(`
            <div class="tool-card ${locked ? 'locked' : ''}">
                <img src="${tool.img}" class="tool-img">
                <div class="tool-name">${tool.name}</div>
                <div class="tool-price">$${tool.price.toLocaleString()}</div>
                <div class="tool-req">Requer Nível ${tool.level}</div>
                <button class="buy-btn" ${locked ? 'disabled' : ''} onclick="buyTool('${tool.item}', ${tool.price})">
                    ${locked ? 'BLOQUEADO' : 'COMPRAR'}
                </button>
            </div>
        `);
    });
}

function renderTasks() {
    $("#tasks-container").empty();
    jobTasks.forEach(task => {
        let currentProgress = (task.type === "items") ? playerStats.totalItems : playerStats.totalTasks;
        if (currentProgress > task.goal) currentProgress = task.goal;
        let percent = (currentProgress / task.goal) * 100;
        let isComplete = currentProgress >= task.goal;
        let isClaimed = claimedTasksLocal.includes(task.id);

        let buttonHTML = isClaimed ? `<button class="task-btn claimed" disabled>Reivindicada</button>` : 
            (isComplete ? `<button class="task-btn" onclick="claimTask('${task.id}', ${task.rewardXP}, ${task.rewardMoney})">Reivindicar</button>` : 
            `<button class="task-btn" disabled>Em Progresso</button>`);

        $("#tasks-container").append(`
            <div class="task-card">
                <div class="task-header">
                    <div><h3 class="task-title">${task.title}</h3><p class="task-desc">${task.desc}</p></div>
                    <div class="task-rewards">
                        <div class="task-reward-badge xp">${task.rewardXP} XP</div>
                        <div class="task-reward-badge money">$${task.rewardMoney}</div>
                    </div>
                </div>
                <div class="task-progress-container">
                    <div class="task-progress-bar"><div class="task-progress-fill" style="width: ${percent}%;"></div></div>
                    <div class="task-progress-text">${currentProgress} / ${task.goal}</div>
                    ${buttonHTML}
                </div>
            </div>
        `);
    });
}

function renderVehicles() {
    $("#vehicles-list").empty();
    jobVehicles.forEach(veh => {
        const locked = userLevel < veh.level;
        $("#vehicles-list").append(`
            <div class="tool-card ${locked ? 'locked' : ''}">
                <img src="${veh.img}" class="vehicle-img">
                <div class="tool-name">${veh.name}</div>
                <div class="tool-price" style="color: ${veh.price == 0 ? '#2ecc71' : '#fff'};">
                    ${veh.price == 0 ? 'GRATUITO' : '$'+veh.price.toLocaleString()}
                </div>
                <div class="tool-req">Requer Nível ${veh.level}</div>
                <button class="buy-btn" ${locked ? 'disabled' : ''} onclick="spawnVehicle('${veh.model}', ${veh.price})">
                    ${locked ? 'BLOQUEADO' : 'RETIRAR'}
                </button>
            </div>
        `);
    });
}

// --- COMUNICAÇÃO COM O SERVIDOR (POSTS) ---

function spawnVehicle(model, price) { $.post(`https://${GetParentResourceName()}/spawnVehicle`, JSON.stringify({ model: model, price: price })); closeTablet(); }
function buyTool(itemName, price) { $.post(`https://${GetParentResourceName()}/buyTool`, JSON.stringify({ item: itemName, price: price })); }
function claimTask(taskId, xpReward, moneyReward) { claimedTasksLocal.push(taskId); renderTasks(); $.post(`https://${GetParentResourceName()}/claimTask`, JSON.stringify({ taskId: taskId, xp: xpReward, money: moneyReward })); }

function fetchLeaderboard() { 
    $("#leaderboard-results").html("<tr><td colspan='4' style='text-align:center;'>A carregar...</td></tr>");
    $.post(`https://${GetParentResourceName()}/getLeaderboard`, JSON.stringify({ job: currentJobName }), function(data) { 
        $("#leaderboard-results").empty(); 
        if (data) { 
            data.forEach((u, i) => { 
                $("#leaderboard-results").append(`<tr><td>#${i+1}</td><td>${u.name}</td><td>${u.stat}</td><td>Lvl ${u.level}</td></tr>`); 
            }); 
        } 
    }); 
}

function closeTablet() { 
    $("#tablet-container").fadeOut(500); 
    $.post(`https://${GetParentResourceName()}/close`, JSON.stringify({})); 
}

// Fechar com ESC
document.onkeyup = function(data) { if (data.which == 27) { closeTablet(); } };