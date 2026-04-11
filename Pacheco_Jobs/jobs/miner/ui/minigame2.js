let smeltActive = false;
let smeltProgress = 0;
let currentSequence = [];
let currentIndex = 0;
const keys = ['W', 'A', 'S', 'D'];

$(document).ready(function() {
    $.get("../jobs/miner/ui/minigame2.html", function(data) {
        if ($("#smelting-container").length === 0) $('body').append(data);
    }).fail(function() {
        $.get(`https://${GetParentResourceName()}/jobs/miner/ui/minigame2.html`, function(data) {
            $('body').append(data);
        });
    });
});

window.addEventListener('message', function(event) {
    if (event.data.action === "startSmeltingGame") {
        setTimeout(startSmelting, 200);
    }
    if (event.data.action === "stopSmeltingGame") {
        stopSmeltingSilently();
    }
});

function startSmelting() {
    smeltActive = true;
    smeltProgress = 0;
    updateProgressUI();
    generateKeys();
    $("#smelting-container").fadeIn(200);
}

function stopSmeltingSilently() {
    smeltActive = false;
    $("#smelting-container").fadeOut(200);
}

function generateKeys() {
    currentSequence = [];
    currentIndex = 0;
    $("#sm-keys").empty();
    for (let i = 0; i < 4; i++) {
        let randomKey = keys[Math.floor(Math.random() * keys.length)];
        currentSequence.push(randomKey);
        $("#sm-keys").append(`<div class="sm-key" id="sm-key-${i}">${randomKey}</div>`);
    }
    updateKeyVisuals();
}

function updateKeyVisuals() {
    $(".sm-key").removeClass("active success error");
    for (let i = 0; i < 4; i++) {
        if (i < currentIndex) $(`#sm-key-${i}`).addClass("success");
        else if (i === currentIndex) $(`#sm-key-${i}`).addClass("active");
    }
}

document.addEventListener("keydown", function(e) {
    if (!smeltActive) return;
    let pressedKey = e.key.toUpperCase();
    
    if (pressedKey === "ESCAPE") return endSmelting(false);

    if (keys.includes(pressedKey)) {
        if (pressedKey === currentSequence[currentIndex]) {
            currentIndex++;
            updateKeyVisuals();
            if (currentIndex >= 4) {
                smeltProgress += 25;
                updateProgressUI();
                if (smeltProgress >= 100) {
                    smeltActive = false;
                    setTimeout(() => { endSmelting(true); }, 500);
                } else {
                    smeltActive = false;
                    setTimeout(() => { generateKeys(); smeltActive = true; }, 400);
                }
            }
        } else {
            $(`#sm-key-${currentIndex}`).addClass("error");
            smeltActive = false;
            setTimeout(() => { currentIndex = 0; updateKeyVisuals(); smeltActive = true; }, 500);
        }
    }
});

function updateProgressUI() {
    $("#sm-percentage").text(smeltProgress + "%");
    $("#sm-progress-fill").css("width", smeltProgress + "%");
}

function endSmelting(success) {
    smeltActive = false;
    $("#smelting-container").fadeOut(200);
    $.post(`https://${GetParentResourceName()}/smeltingResult`, JSON.stringify({ success: success }));
}