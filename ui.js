const setUI = (enable) => {
    if(enable)
        document.getElementById("content").style.display = "block";
    else
        document.getElementById("content").style.display = "none";
}

const templateCompany = `
<tr class="stock">
    <th scope="row">ID</th>
    <td>ABR</td>
    <td>FULLNAME</td>
    <td id="ABR_owned">OWNED</td>
    <td id="ABR_worth">$ WORTH</td>
    <td>
        <div class="btn-toolbar mb-3" role="toolbar" aria-label="Toolbar with button groups">
            <div class="btn-group mr-2" role="group" aria-label="First group">
                <button type="button" id="ABR_buy" class="btn btn-primary">Buy</button>
                <button type="button" id="ABR_sell" class="btn btn-secondary">Sell</button>
            </div>
            <div class="input-group">
                <div class="input-group-prepend">
                    <div class="input-group-text" id="btnGroupAddon">Amount</div>
                </div>
                <input type="text" id="ABR_amount" class="form-control" value="1" aria-label="1"
                    aria-describedby="btnGroupAddon">
            </div>
        </div>
    </td>
</tr>
`

const addCompany = (abbreviation, name, owned, worth) => {
    let modifiedTemplate = templateCompany;
    modifiedTemplate = modifiedTemplate.replace("ID", (document.getElementsByClassName("stock").length + 1))
    modifiedTemplate = modifiedTemplate.replace(/ABR/g, abbreviation)
    modifiedTemplate = modifiedTemplate.replace("FULLNAME", name)
    modifiedTemplate = modifiedTemplate.replace("OWNED", owned)
    modifiedTemplate = modifiedTemplate.replace("WORTH", worth)

    document.getElementById("stockmarket").innerHTML += modifiedTemplate;

    document.getElementById(`${abbreviation}_buy`).onclick = function() {
        fetch(`https://${GetParentResourceName()}/buy`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                stock: abbreviation,
                amount: document.getElementById(`${abbreviation}_amount`).value
            })
        })
    }

    document.getElementById(`${abbreviation}_sell`).onclick = function() {
        fetch(`https://${GetParentResourceName()}/sell`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                stock: abbreviation,
                amount: document.getElementById(`${abbreviation}_amount`).value
            })
        })
    }
}

document.getElementById("close").onclick = function(){
    setUI(false)
    fetch(`https://${GetParentResourceName()}/close`, {})
}

window.addEventListener('message', (event) => {
    if (event.data.type === 'open') {
        setUI(true)
    }

    if (event.data.type === 'close') {
        setUI(false)
    }

    if (event.data.type === 'update') {
        const stocks = JSON.parse(event.data.stocks);

        document.getElementById("stockmarket").innerHTML = "";
        for(let stock of stocks) {
            addCompany(stock.abr, stock.name, stock.owned, stock.worth)
        }
    }
});