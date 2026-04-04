window.addEventListener('message', function(event) {
    if (event.data.action === "openTablet") {
        $("#tablet-container").fadeIn();
        const d = event.data.data;
        
        $("#user-name").text(d.name);
        $("#stat-earned").text(d.totalEarned);
        $("#stat-mined").text(d.rocksMined);
        $("#stat-processed").text(d.oresProcessed);
        $("#stat-gems").text(d.gemsCut);
        $("#stat-xp").text(d.xp);
        $("#stat-points").text(d.skillsPoints);
        $(".user-lvl-circle").text(d.level);
    }
});

function closeTablet() {
    $("#tablet-container").fadeOut();
    $.post(`https://${GetParentResourceName()}/close`, JSON.stringify({}));
}

document.onkeyup = function(data) {
    if (data.which == 27) { closeTablet(); } // ESC
};