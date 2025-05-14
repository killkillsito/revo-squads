let isOwner = false
let ownerSource = 0
$(document).on("keyup", (e) => { 
    switch (e.which) {
        case 27:
            $.post("https://gfx-squad/closeUI");
            break;
    }
})

window.addEventListener("message", function (e) { 
    const data = e.data
    switch (data.type) {
        case "displayMenu":
            isOwner = data.menu != "public" ? (data.squad.members[0].source == data.source) : false
            ownerSource =  data.menu != "public" ? data.squad.members[0].source : 0
            DisplayMenu(data)
            break;
        case "displayHud":
            DisplayHud(data)
            break;
        default:
            break;
    }
})

ChangePages = page => {
    if (page == "public") {
        $(".gfxsquan-menu-content").show()
        $(".gfxsquan-squadmenu-content").hide()
        $(".header-title > p").html("PUBLIC")
    } else {
        $(".header-title > p").html("MY")

        $(".gfxsquan-menu-content").hide()
        $(".gfxsquan-squadmenu-content").show()
    }
}

DisplayMenu = data => {
    if (data.bool) {
        if(data.squad){
            ChangePages(data.menu)
            if (data.menu == "public") {
                LoadSquads(data.squad)
            } else {
                SetMySquad(data.squad)
            }    
        }
        if ($(".gfxsquan-menu-contain").css("display")!="flex" && data.force){
            $(".gfxsquan-menu-contain").css("display", "flex").hide().fadeIn(250);
        }
    } else {
        $(".gfxsquan-menu-contain").fadeOut(250)
    }
}

DisplayHud = data => {
    if (data.bool) {
        $(".gfxsquad").css("display", "flex").show();
        if (data.members) {
            $(".squad-member").remove()
            for (let i = 0; i < data.members.length; i++) {
                const element = data.members[i];
                if (element.hudData) {
                    if (element.hudData.maxHealth == 200) {
                        element.hudData.maxHealth = 100
                        element.hudData.health -= 100
                    }
                }
                // console.log(JSON.stringify(element.hudData))
                const content = `
                <div class="squad-member">
                    <img src=${element.image} alt="">
                        <div class="members-informations">
                            <h1>${element.name}</h1>
                            <div class="members-progressbars">
                                <div class="members-armor-bar"><div style="width: ${element.hudData ? element.hudData.armor : 0}%" class="fill"></div></div>
                                <div class="members-hp-bar"><div style="width: ${element.hudData ? (element.hudData.health / element.hudData.maxHealth) * 100 : 0}%" class="fill"></div></div>
                            </div>
                            </div>
                        </div>
                </div>
                `
                $(".gfxsquad").append(content);
            }
        }
    } else {
        $(".gfxsquad").fadeOut(250)
    }
}

LoadSquads = squads => {
    $(".gfxsquan-menu-content > .content-squads").remove();
    $.each(squads, function (k, v) { 
        if (!v.private) {
            const content = `
            <div class="content-squads">
                <div class="squads-firstsections">
                    <img src=${v.members[0].image ? v.members[0].image : "https://fiverr-res.cloudinary.com/image/upload/f_auto,q_auto/v1/secured-attachments/messaging_message/attachment/e29bc0c9919309d70a3a3d61a9db4afb-1665957539580/immagine_2022-10-16_235859337.png?__cld_token__=exp=1666999251~hmac=b19078db8e45e8e1256770b9a9e9a9e88e4bd0cb7bca4b771b75ef1814df201f"} alt="">
                    <div class="firstsections-content">
                        <h1>${v.members[0].name} SQUAD</h1>
                        <p>MEMBERS</p>
                        <div class="firstsection-member">
                        ${
                            v.members.map(e => {
                                if (e && e.image != v.members[0].image) {
                                    return `<img src=${e.image} alt=""></img>`
                                }
                            }).join('')
                        }
                        </div>
                    </div>
                </div>
                <button class="squads-secondsections" data-id=${k}><p>JOIN</p></button>
            </div>
            `
            $(".gfxsquan-menu-content").append(content);    
        }
    });
}

SetMySquad = mysquad => {
    $(".squadmenu-members > .member").remove()
    for (let i = 0; i < mysquad.members.length; i++) {
        const element = mysquad.members[i];
        if (element.hudData) {
            if (element.hudData.maxHealth == 200) {
                element.hudData.maxHealth = 100
                element.hudData.health -= 100
            }
        }
        console.log(JSON.stringify(element))
        const content = `
            <div class="member">
                <img src=${element.image} alt="">
                <div class="members-informations">
                    <h1>${element.name}</h1>
                    <div class="members-progressbars">
                        <div class="members-armor-bar"><div style="width: ${element.hudData ? element.hudData.armor : 0}%" class="fill"></div></div>
                        <div class="members-hp-bar"><div style="width: ${element.hudData ? (element.hudData.health / element.hudData.maxHealth) * 100 : 0}%" class="fill"></div></div>  
                    </div>
                    ${
                        isOwner && element.source != ownerSource ? 
                            `
                                <div class="buttons-div" data-id=${element.source}>
                                    <div class="button"><p>KICK</p></div>
                                </div>
                            ` : ""
                        
                    }
                    
                </div>
            </div>
        `
        $(".squadmenu-members").append(content);
    }
    $("#private").prop("checked", mysquad.private)
    $("#disband > p").html(isOwner ? "DISBAND" : "LEAVE")
    $("#disband").parent().find(".setting-info > p").html("Click for delete your squad")
}

$(document).on("click", ".header-create", function () {
    $.post("https://gfx-squad/CreateNew");
});

$(document).on("click", "#disband", function () {
    if (isOwner) {
        $.post("https://gfx-squad/DeleteSquad");
    } else {
        $.post("https://gfx-squad/Leave");
    }
});

$(document).on("change", "#hudVar", function () {
    const status = $(this).prop("checked")
    $.post("https://gfx-squad/HudStatus", JSON.stringify({hud: status}));
});

$(document).on("change", "#private", function () {
    const status = $(this).prop("checked")
    console.log(isOwner, 155)
    if (!isOwner) {$(this).prop("checked", !status); return};
    $.post("https://gfx-squad/PrivateStatus", JSON.stringify({bool: status}));
});

$(document).on("click", ".squads-secondsections", function() { 
    const id = $(this).data("id")
    $.post("https://gfx-squad/Join", JSON.stringify({id}));
})

$(document).on("click", ".buttons-div", function() { 
    const id = $(this).data("id")
    $.post("https://gfx-squad/Kick", JSON.stringify({id}));
})