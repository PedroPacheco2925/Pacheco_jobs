$(document).ready(function() {
    $.get("../jobs/miner/ui/shop.html", function(data) {
        if ($("#shop-container").length === 0) $('body').append(data);
    }).fail(function() {
        $.get(`https://${GetParentResourceName()}/jobs/miner/ui/shop.html`, function(data) {
            $('body').append(data);
        });
    });

    // Fechar no botão e no ESC
    $(document).on('click', '#close-shop', closeShop);
    document.addEventListener('keydown', function(e) {
        if (e.key === "Escape" && $("#shop-container").is(":visible")) {
            closeShop();
        }
    });

    // Botão de Vender
    $(document).on('click', '.sell-btn', function() {
        let itemName = $(this).data('item');
        let amount = $(`#input-${itemName}`).val();

        if (amount > 0) {
            $.post(`https://${GetParentResourceName()}/sellItem`, JSON.stringify({
                itemName: itemName,
                amount: amount
            }));
        }
    });
});

window.addEventListener('message', function(event) {
    if (event.data.action === "openShop") {
        renderShopItems(event.data.items);
        $("#shop-container").fadeIn(200);
    }
});

function closeShop() {
    $("#shop-container").fadeOut(200);
    $.post(`https://${GetParentResourceName()}/closeShop`, JSON.stringify({}));
}

function renderShopItems(items) {
    let html = "";
    items.forEach(item => {
        let disabled = item.count <= 0 ? "disabled" : "";
        let maxVal = item.count > 0 ? item.count : 0;
        
        html += `
        <div class="shop-item">
            <div class="item-info">
                <span class="item-name">${item.label}</span>
                <span class="item-stock">No Inventário: <b>${item.count}</b></span>
                <span class="item-price">$${item.price} /unidade</span>
            </div>
            <div class="item-action">
                <input type="number" id="input-${item.name}" class="sell-input" min="1" max="${maxVal}" value="${maxVal > 0 ? 1 : 0}" ${disabled}>
                <button class="sell-btn" data-item="${item.name}" ${disabled}>VENDER</button>
            </div>
        </div>`;
    });
    $("#shop-item-list").html(html);
}