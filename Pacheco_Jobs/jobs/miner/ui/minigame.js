let mgActive = false;
let mgProgress = 0;
let cursorPosition = 0;
let cursorDirection = 1;
let cursorSpeed = 1.5; // Velocidade base calculada para 60FPS
let hitPower = 20; 
let sweetSpotStart = 0;
let sweetSpotEnd = 0;
let animationFrame;
let lastTime = 0; // NOVA VARIÁVEL: Guarda o tempo do último frame

// ==========================================
// 1. INJETAR O HTML
// ==========================================
$(document).ready(function() {
    const path = "../jobs/miner/ui/minigame.html";

    $.get(path, function(htmlData) {
        if ($("#minigame-container").length === 0) {
            $('body').append(htmlData);
        }
    }).fail(function() {
        let resourceName = GetParentResourceName();
        $.get(`https://${resourceName}/jobs/miner/ui/minigame.html`, function(data) {
            $('body').append(data);
        });
    });
});

// ==========================================
// 2. ESCUTAR O LUA
// ==========================================
window.addEventListener('message', function(event) {
    let item = event.data;

    if (item.action === "startMiningGame") {
        if (item.hitPower) {
            hitPower = item.hitPower;
        }

        if ($("#minigame-container").length > 0) {
            startMinigame();
        } else {
            setTimeout(startMinigame, 200);
        }
    }

    // NOVA LÓGICA: ESCUTAR O CANCELAMENTO DO F6
    if (item.action === "stopMiningGame") {
        stopMiningGameSilently();
    }
});

function startMinigame() {
    mgActive = true;
    mgProgress = 0;
    $("#mg-percentage").text("0%");
    $("#mg-progress-fill").css("width", "0%"); 
    
    randomizeSweetSpot();
    
    $("#minigame-container").fadeIn(200); 
    
    cursorPosition = 0;
    cursorDirection = 1;
    cursorSpeed = 1.5; 
    
    // Reseta o tempo para o cálculo perfeito
    lastTime = performance.now();
    animationFrame = requestAnimationFrame(gameLoop);
}

// Função para fechar o jogo quando o Lua manda (F6)
// Não envia resposta de volta para o Lua para evitar loops, já que o Lua já sabe que parou.
function stopMiningGameSilently() {
    mgActive = false;
    cancelAnimationFrame(animationFrame);
    $("#minigame-container").fadeOut(200);
}

function randomizeSweetSpot() {
    sweetSpotStart = Math.floor(Math.random() * 50) + 15;
    sweetSpotEnd = sweetSpotStart + 20;
    $("#mg-sweet-spot").css({ "left": sweetSpotStart + "%", "width": "20%" });
}

// ==========================================
// LÓGICA DO LOOP COM DELTA TIME (INFALÍVEL)
// ==========================================
function gameLoop(timestamp) {
    if (!mgActive) return;
    
    // Calcula o Delta Time (quanto tempo passou desde o último frame)
    if (!lastTime) lastTime = timestamp;
    let deltaTime = timestamp - lastTime;
    lastTime = timestamp;

    // 16.66ms é o tempo perfeito de um frame a 60 FPS. 
    // Se a pessoa tiver 144 FPS, o deltaTime é menor (~6.9ms), logo compensamos a velocidade.
    let timeCorrection = deltaTime / 16.66;
    if (timeCorrection > 3) timeCorrection = 3; // Previne saltos enormes se houver muito lag
    
    // Multiplicamos a velocidade pela correção de tempo
    cursorPosition += (cursorSpeed * timeCorrection) * cursorDirection;
    
    if (cursorPosition >= 100) { cursorPosition = 100; cursorDirection = -1; }
    if (cursorPosition <= 0) { cursorPosition = 0; cursorDirection = 1; }
    
    $("#mg-cursor").css("left", cursorPosition + "%");
    
    animationFrame = requestAnimationFrame(gameLoop);
}

// ==========================================
// 3. TECLAS E LÓGICA DE HIT
// ==========================================
document.addEventListener("keydown", function(e) {
    if (!mgActive) return;

    if (e.code === "Space") {
        e.preventDefault(); 
        checkHit();
    }
    
    if (e.code === "Escape") {
        endMinigame(false);
    }
});

function checkHit() {
    if (cursorPosition >= sweetSpotStart && cursorPosition <= sweetSpotEnd) {
        mgProgress += hitPower; 
        if (mgProgress > 100) mgProgress = 100;

        $("#mg-percentage").text(mgProgress + "%");
        $("#mg-progress-fill").css("width", mgProgress + "%");

        $.post(`https://${GetParentResourceName()}/playStrikeAnim`, JSON.stringify({}));

        if (mgProgress >= 100) {
            setTimeout(() => { 
                endMinigame(true); 
                mgProgress = 0; 
            }, 400);
        } else {
            randomizeSweetSpot(); 
        }
    } else {
        mgProgress = 0;
        $("#mg-percentage").text("0%");
        $("#mg-progress-fill").css("width", "0%");
        $.post(`https://${GetParentResourceName()}/playFailAnim`, JSON.stringify({}));
    }
}

function endMinigame(success) {
    if (!mgActive) return;
    mgActive = false;
    cancelAnimationFrame(animationFrame);
    $("#minigame-container").fadeOut(200);
    $.post(`https://${GetParentResourceName()}/minigameResult`, JSON.stringify({ success: success }));
}