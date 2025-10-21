window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'showDice') {
        showDiceUI(data);
    } else if (data.action === 'removeDice') {
        removeDiceUI(data.diceId);
    }
});

function showDiceUI(data) {
    const container = document.getElementById('diceContainer');
    
    // Remove existing element if it exists
    const existing = document.getElementById('dice-' + data.diceId);
    if (existing) {
        existing.remove();
    }
    
    const diceElement = document.createElement('div');
    diceElement.className = 'dice-ui';
    diceElement.id = 'dice-' + data.diceId;
    diceElement.textContent = data.result;
    
    // Position the UI element using percentages
    diceElement.style.left = data.screenX + '%';
    diceElement.style.top = data.screenY + '%';
    
    container.appendChild(diceElement);
}

function removeDiceUI(diceId) {
    const element = document.getElementById('dice-' + diceId);
    if (element) {
        element.remove();
    }
}
