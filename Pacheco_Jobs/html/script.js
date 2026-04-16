// =========================================
// VARIAVEIS GLOBAIS
// =========================================
let currentJobName = "";
let userLevel = 1;
let jobTools = [];
let jobTasks = [];
let jobVehicles = [];
let playerStats = { totalItems: 0, totalTasks: 0 }; 
let claimedTasksGlobal = [];

// =========================================
// NAVEGAÇÃO ENTRE ABAS
// =========================================
function showView(view) {
    $("#dashboard-view, #leaderboard-view, #tools-view, #tasks-view, #vehicles-view").hide();
    
    if (view === "dashboard") { 
        $("#dashboard-view").show(); 
        $("#section-title").text("OVERVIEW"); 
    } 
    else if (view === "leaderboard") { 
        $("#leaderboard-view").show(); 
        $("#section-title").text("RANKING TOP 10"); 
        fetchLeaderboard(); 
    } 
    else if (view === "tools") { 
        $("#tools-view").show(); 
        $("#section-title").text("LOJA DE EQUIPAMENTO"); 
        renderTools(); 
    } 
    else if (view === "tasks") { 
        $("#tasks-view").show(); 
        $("#section-title").text("PROGRESSÃO E MISSÕES"); 
        renderTasks(); 
    } 
    else if (view === "vehicles") { 
        $("#vehicles-view").show(); 
        $("#section-title").text("GARAGEM DA EMPRESA"); 
        renderVehicles(); 
    }
}

// =========================================
// ESCUTA DE MENSAGENS (LUA -> NUI)
// =========================================
window.addEventListener('message', function(event) {
    let data = event.data;

    if (data.action === "openTablet") {
        $("#jobcenter-container").hide(); 
        $("#tablet-container").fadeIn(500);
        
        currentJobName = data.jobName;
        const d = data.data;
        const cfg = data.config;

        jobTools = cfg.Tools || [];
        jobTasks = cfg.Tasks || [];
        jobVehicles = cfg.Vehicles || [];
        playerStats.totalItems = d.totalItems || 0;
        playerStats.totalTasks = d.totalTasks || 0;
        claimedTasksGlobal = d.claimedTasks || [];

        $("#brand-title").text(cfg.JobTitle);
        $("#brand-subtitle").text(cfg.JobSubtitle);
        $("#user-role").text(cfg.RoleName);
        $("#brand-icon").attr("class", cfg.BrandIcon + " logo-icon");
        $("#user-name").text(d.name);
        
        // =========================================
        // BARRA DE XP E NÍVEL 100% DINÂMICA (LÊ O CONFIG)
        // =========================================
        let currentXP = d.xp || d.skillsPoints || 0; 

        // 1. Normalizar a tabela do config (Resolve o bug do Lua vs JS)
        let xpTable = {};
        if (Array.isArray(cfg.Levels)) {
            cfg.Levels.forEach((xp, index) => { xpTable[index + 1] = xp; });
        } else {
            xpTable = cfg.Levels || {1: 0, 2: 1000, 3: 40000, 4: 100000};
        }

        // 2. Descobrir o Nível Real apenas olhando para o XP
        let realLevel = 1;
        let maxLvl = Math.max(...Object.keys(xpTable).map(Number));

        for (let i = 1; i <= maxLvl; i++) {
            if (currentXP >= xpTable[i]) {
                realLevel = i;
            }
        }

        userLevel = realLevel; 
        $("#user-level").text(userLevel); 

        // 3. Descobrir os limites para a barra
        let prevLevelXP = xpTable[userLevel];
        let nextLevelXP = xpTable[userLevel + 1];

        if (nextLevelXP === undefined) { 
            nextLevelXP = prevLevelXP; 
        }

        // 4. Matemática da Barra
        let xpRequiredInRange = nextLevelXP - prevLevelXP;
        let xpGainedInRange = currentXP - prevLevelXP;
        
        let xpPercent = 100;
        if (xpRequiredInRange > 0) {
            xpPercent = Math.min((xpGainedInRange / xpRequiredInRange) * 100, 100);
        }

        $("#user-current-xp").text(currentXP);
        $("#user-next-xp").text(nextLevelXP); 
        $("#user-xp-fill").css("width", xpPercent + "%");
        // =========================================

        // Atualizar Stats Visuais
        $("#stat-earned").text(d.totalEarned || 0);
        $("#stat-xp").text(currentXP); 
        $("#stat-points").text(d.skillsPoints || 0);
        $("#custom-val-1").text(playerStats.totalItems);
        $("#custom-val-2").text(playerStats.totalTasks);

        $(".nav-item").removeClass("active");
        $('.nav-item[data-target="dashboard"]').addClass("active");
        showView("dashboard");
    }

    if (data.action === "openJobCenter") {
        $("#tablet-container").hide();
        $("#jobcenter-container").fadeIn(500);
        $("#job-list").empty();

        $("#job-list").append(`
            <div class="jc-job-card" style="border-color: #ef4444;">
                <h3 class="jc-job-title" style="color: #ef4444;"><i class="fas fa-user-slash"></i> Desempregado</h3>
                <p class="jc-job-desc">Sair do emprego atual para procurar algo novo.</p>
                <button class="jc-job-btn unemployed" onclick="selectJob('unemployed', 'Desempregado')">Ficar Desempregado</button>
            </div>
        `);

        if (data.jobs) {
            data.jobs.forEach(job => {
                $("#job-list").append(`
                    <div class="jc-job-card">
                        <h3 class="jc-job-title"><i class="fas fa-briefcase"></i> ${job.label}</h3>
                        <p class="jc-job-desc">${job.description}</p>
                        <button class="jc-job-btn" onclick="selectJob('${job.job}', '${job.label}')">Assinar Contrato</button>
                    </div>
                `);
            });
        }
    }
});

// =========================================
// FUNÇÕES DE RENDERIZAÇÃO
// =========================================

function renderTools() {
    let html = '';
    
    jobTools.forEach(tool => {
        const isLocked = userLevel < tool.level;
        const lockClass = isLocked ? 'locked' : '';
        const buttonText = isLocked ? 'BLOQUEADO' : 'COMPRAR';
        const buttonDisabled = isLocked ? 'disabled' : '';
        
        const levelRequirement = isLocked ? 
            `<div class="tool-req locked-req"><i class="fas fa-lock"></i> DESBLOQUEIA NÍVEL ${tool.level}</div>` : 
            `<div class="tool-req">Requisito: Nível ${tool.level}</div>`;

        html += `
            <div class="tool-card ${lockClass}">
                <img src="${tool.img}" class="tool-img">
                <div class="tool-name">${tool.name}</div>
                <div class="tool-price">$${tool.price.toLocaleString()}</div>
                ${levelRequirement}
                <button class="buy-btn" ${buttonDisabled} onclick="buyTool('${tool.item}', ${tool.price})">
                    ${buttonText}
                </button>
            </div>
        `;
    });
    
    $('#tools-list').html(html);
}

function renderVehicles() {
    $("#vehicles-list").empty();
    jobVehicles.forEach(veh => {
        const locked = userLevel < veh.level;
        $("#vehicles-list").append(`
            <div class="tool-card ${locked ? 'locked' : ''}">
                <img src="${veh.img}" class="vehicle-img">
                <div class="tool-name">${veh.name}</div>
                <div class="tool-price">${veh.price == 0 ? 'GRATUITO' : '$'+veh.price.toLocaleString()}</div>
                <button class="buy-btn" ${locked ? 'disabled' : ''} onclick="spawnVehicle('${veh.model}', ${veh.price})">
                    ${locked ? 'BLOQUEADO' : 'RETIRAR'}
                </button>
            </div>
        `);
    });
}

function renderTasks() {
    $("#tasks-container").empty();
    jobTasks.forEach(task => {
        let current = (task.type === "items") ? playerStats.totalItems : playerStats.totalTasks;
        let percent = Math.min((current / task.goal) * 100, 100);
        let claimed = claimedTasksGlobal.includes(task.id);
        
        $("#tasks-container").append(`
            <div class="task-card">
                <div class="task-header">
                    <div>
                        <h3 class="task-title">${task.title}</h3>
                        <p class="task-desc">${task.desc}</p>
                    </div>
                    <div class="task-rewards">
                        <div class="task-reward-badge xp">${task.rewardXP} XP</div>
                        <div class="task-reward-badge money">$${task.rewardMoney}</div>
                    </div>
                </div>
                <div class="task-progress-bar"><div class="task-progress-fill" style="width: ${percent}%;"></div></div>
                <div class="task-progress-text">${current} / ${task.goal}</div>
                <button class="task-btn" ${claimed || current < task.goal ? 'disabled' : ''} onclick="claimTask('${task.id}', ${task.rewardXP}, ${task.rewardMoney})">
                    ${claimed ? 'REIVINDICADA' : (current >= task.goal ? 'REIVINDICAR' : 'EM PROGRESSO')}
                </button>
            </div>
        `);
    });
}

// =========================================
// AÇÕES E COMUNICAÇÃO LUA (POST)
// =========================================

function buyTool(item, price) {
    $.post(`https://${GetParentResourceName()}/buyTool`, JSON.stringify({ item: item, price: price }));
}

function spawnVehicle(model, price) {
    $.post(`https://${GetParentResourceName()}/spawnVehicle`, JSON.stringify({ model: model, price: price }));
    closeTablet(); 
}

function claimTask(id, xp, money) {
    claimedTasksGlobal.push(id);
    renderTasks(); 
    $.post(`https://${GetParentResourceName()}/claimTask`, JSON.stringify({
        taskId: id,
        jobName: currentJobName,
        xp: xp,
        money: money
    }));
}

function selectJob(id, label) {
    $.post(`https://${GetParentResourceName()}/selectJob`, JSON.stringify({ jobId: id, jobLabel: label }));
    closeJobCenter();
}

function fetchLeaderboard() {
    $.post(`https://${GetParentResourceName()}/getLeaderboard`, JSON.stringify({ job: currentJobName }), function(data) {
        $("#leaderboard-results").empty();
        if (data && data.length > 0) {
            data.forEach((u, i) => { 
                $("#leaderboard-results").append(`
                    <tr>
                        <td class="lead-pos">#${i+1}</td>
                        <td class="lead-name">${u.name}</td>
                        <td class="lead-stat">${u.stat.toLocaleString()}</td>
                        <td><span class="lead-lvl">Lvl ${u.level}</span></td>
                    </tr>
                `); 
            });
        }
    });
}

// =========================================
// GESTÃO DE FECHO E INTERAÇÃO
// =========================================

function closeTablet() {
    $("#tablet-container").fadeOut(500);
    $.post(`https://${GetParentResourceName()}/close`, JSON.stringify({}));
}

function closeJobCenter() {
    $("#jobcenter-container").fadeOut(500);
    $.post(`https://${GetParentResourceName()}/closeJobCenter`, JSON.stringify({}));
}

$(document).on('click', '.nav-item', function() {
    const target = $(this).data("target");
    if (target) {
        $(".nav-item").removeClass("active");
        $(this).addClass("active");
        showView(target);
    }
});

document.onkeyup = function(d) {
    if (d.which == 27) {
        closeTablet();
        closeJobCenter();
    }
};