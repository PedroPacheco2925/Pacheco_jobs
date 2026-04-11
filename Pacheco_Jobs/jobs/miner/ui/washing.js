let isDragging = false;
let stone = null;
let currentQuantity = 1;
let maxQuantity = 0;

// Variáveis de Configuração vindas do Lua
let configBatchSize = 2;
let configBatchTime = 3000;

$(document).ready(function() {
    $.get(`../jobs/miner/ui/washing.html`, function(htmlData) {
        if ($("#washing-container").length === 0) {
            $('body').append(htmlData);
            stone = $("#stone-item");
            setupDraggable();
        }
    });
});

window.addEventListener('message', function(event) {
    let data = event.data;
    if (data.action === "openWashing") {
        maxQuantity = data.count || 0;
        configBatchSize = data.batchSize || 2;
        configBatchTime = data.batchTime || 3000;

        $("#stone-total-count").text(maxQuantity + "x");
        $("#washing-container").fadeIn(400).css("display", "flex");
        resetWashing();
    }
});

function setupDraggable() {
    $(document).on('mousedown', '#stone-item', function(e) {
        if (isDragging) return;
        isDragging = true;
        $(this).addClass('dragging');
        updatePosition(e);
    });

    $(document).on('mousemove', function(e) {
        if (isDragging) updatePosition(e);
    });

    $(document).on('mouseup', function(e) {
        if (isDragging) {
            isDragging = false;
            stone.removeClass('dragging');
            checkDrop(e);
        }
    });
}

function updatePosition(e) {
    stone.css({ left: e.pageX - 50 + 'px', top: e.pageY - 50 + 'px' });
}

function checkDrop(e) {
    const dropZone = document.getElementById('drop-zone');
    if (!dropZone) return;
    
    const rect = dropZone.getBoundingClientRect();

    if (e.pageX >= rect.left && e.pageX <= rect.right &&
        e.pageY >= rect.top && e.pageY <= rect.bottom) {
        
        stone.hide();
        $("#drop-content").hide();
        $("#stone-deposited").show();
        $("#main-washing-area").css("opacity", "0.3");
        $("#quantity-modal").fadeIn(300);
    } else {
        stone.css({ top: 'auto', left: 'auto', position: 'relative' });
    }
}

function changeQty(val) {
    let input = $("#wash-quantity");
    let newVal = parseInt(input.val()) + val;
    if (newVal >= 1 && newVal <= maxQuantity) {
        input.val(newVal);
    }
}

// ==========================================
// AQUI ESTÁ A MUDANÇA PRINCIPAL DO JS
// ==========================================
function confirmWashing() {
    currentQuantity = parseInt($("#wash-quantity").val());
    
    // Manda a ordem para o Lua começar a animação e o processo
    $.post(`https://${GetParentResourceName()}/startWashingProcess`, JSON.stringify({
        quantity: currentQuantity
    }));
    
    // Fecha a UI imediatamente para o jogador ver o jogo
    closeWashing();
}

function resetWashing() {
    $("#quantity-modal").hide();
    $("#process-area").hide();
    $("#main-washing-area").css("opacity", "1");
    $("#stone-deposited").hide();
    $("#drop-content").show();
    $("#stone-item").show().css({ top: 'auto', left: 'auto', position: 'relative' });
    $("#wash-quantity").val(1);
}

function closeWashing() {
    $("#washing-container").fadeOut(400);
    $.post(`https://${GetParentResourceName()}/closeWashingUI`, JSON.stringify({}));
}

$(document).keyup(function(e) { if (e.key === "Escape") closeWashing(); });