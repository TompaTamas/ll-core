// Cutscene Creator - Complete JavaScript
// State Management
let currentState = {
    type: null,
    index: null,
    spawnType: null
};

let savedCutscenes = [];
let contextMenuActions = [];

// Message Handler from Game
window.addEventListener('message', (e) => {
    const data = e.data;
    
    switch(data.action) {
        case 'enterCreator':
            handleEnterCreator(data.data);
            break;
        case 'exitCreator':
            handleExitCreator();
            break;
        case 'showUI':
            showFullUI(data.data);
            break;
        case 'hideUI':
            hideFullUI();
            break;
        case 'updateFreecamPos':
            updateFreecamPosition(data.coords, data.rot, data.fov);
            break;
        case 'showContextMenu':
            showContextMenu(data.options);
            break;
        case 'showSpawnMenu':
            showSpawnMenu(data.spawnType);
            break;
        case 'showVec4Editor':
            showVec4Editor(data.data);
            break;
        case 'showOutfitEditor':
            showOutfitEditor(data.index, data.outfit);
            break;
        case 'showAnimationMenu':
            showAnimationMenu(data.index, data.animation);
            break;
        case 'showVehicleModMenu':
            showVehicleModMenu(data.index, data.mods);
            break;
        case 'showVehicleColorMenu':
            showVehicleColorMenu(data.index, data.colors);
            break;
        case 'showAudioMenu':
            showAudioMenu();
            break;
        case 'cutsceneSaved':
            handleCutsceneSaved(data.savedCutscenes);
            break;
        case 'cutsceneLoaded':
            handleCutsceneLoaded(data.cutscene);
            break;
        case 'cutsceneDeleted':
            handleCutsceneDeleted(data.savedCutscenes);
            break;
        case 'keyframeAdded':
            updateStats();
            break;
    }
});

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    initializeEventListeners();
});

function initializeEventListeners() {
    // Expand/Collapse
    const expandBtn = document.getElementById('expandBtn');
    const collapseBtn = document.getElementById('collapseBtn');
    
    if (expandBtn) {
        expandBtn.addEventListener('click', () => sendNUI('closeUI'));
    }
    
    if (collapseBtn) {
        collapseBtn.addEventListener('click', () => sendNUI('closeUI'));
    }
    
    // Save button
    const saveBtn = document.getElementById('saveBtn');
    if (saveBtn) {
        saveBtn.addEventListener('click', saveCutscene);
    }
    
    // Quick actions
    const testPlayBtn = document.getElementById('testPlayBtn');
    if (testPlayBtn) {
        testPlayBtn.addEventListener('click', () => {
            const name = document.getElementById('cutsceneName').value.trim();
            if (name) {
                sendNUI('testPlay', { name });
            } else {
                showNotification('Please enter a cutscene name first', 'warning');
            }
        });
    }
    
    const clearSceneBtn = document.getElementById('clearSceneBtn');
    if (clearSceneBtn) {
        clearSceneBtn.addEventListener('click', () => {
            if (confirm('Clear entire scene? This cannot be undone!')) {
                sendNUI('clearScene');
                updateStats();
            }
        });
    }
    
    const exportBtn = document.getElementById('exportBtn');
    if (exportBtn) {
        exportBtn.addEventListener('click', exportCutscene);
    }
    
    // Modal buttons
    setupModalListeners();
    
    // Keyboard shortcuts
    document.addEventListener('keydown', handleKeyboard);
}

function setupModalListeners() {
    // Spawn Menu
    const confirmSpawn = document.getElementById('confirmSpawn');
    const cancelSpawn = document.getElementById('cancelSpawn');
    
    if (confirmSpawn) {
        confirmSpawn.addEventListener('click', confirmSpawnEntity);
    }
    if (cancelSpawn) {
        cancelSpawn.addEventListener('click', () => hideModal('spawnMenu'));
    }
    
    // Vec4 Editor
    const confirmVec4 = document.getElementById('confirmVec4');
    const cancelVec4 = document.getElementById('cancelVec4');
    
    if (confirmVec4) {
        confirmVec4.addEventListener('click', confirmVec4Update);
    }
    if (cancelVec4) {
        cancelVec4.addEventListener('click', () => hideModal('vec4Editor'));
    }
    
    // Outfit Editor
    const confirmOutfit = document.getElementById('confirmOutfit');
    const cancelOutfit = document.getElementById('cancelOutfit');
    
    if (confirmOutfit) {
        confirmOutfit.addEventListener('click', confirmOutfitUpdate);
    }
    if (cancelOutfit) {
        cancelOutfit.addEventListener('click', () => hideModal('outfitEditor'));
    }
    
    // Animation Menu
    const confirmAnim = document.getElementById('confirmAnim');
    const cancelAnim = document.getElementById('cancelAnim');
    
    if (confirmAnim) {
        confirmAnim.addEventListener('click', confirmAnimationSet);
    }
    if (cancelAnim) {
        cancelAnim.addEventListener('click', () => hideModal('animMenu'));
    }
    
    // Vehicle Mod Menu
    const confirmVehMod = document.getElementById('confirmVehMod');
    const cancelVehMod = document.getElementById('cancelVehMod');
    
    if (confirmVehMod) {
        confirmVehMod.addEventListener('click', confirmVehicleMods);
    }
    if (cancelVehMod) {
        cancelVehMod.addEventListener('click', () => hideModal('vehModMenu'));
    }
    
    // Vehicle Color Menu
    const confirmVehColor = document.getElementById('confirmVehColor');
    const cancelVehColor = document.getElementById('cancelVehColor');
    
    if (confirmVehColor) {
        confirmVehColor.addEventListener('click', confirmVehicleColors);
    }
    if (cancelVehColor) {
        cancelVehColor.addEventListener('click', () => hideModal('vehColorMenu'));
    }
}

function handleKeyboard(e) {
    // ESC - Close modals or UI
    if (e.key === 'Escape') {
        const openModal = document.querySelector('.modal:not(.hidden)');
        if (openModal) {
            openModal.classList.add('hidden');
        } else {
            sendNUI('closeUI');
        }
    }
    
    // Ctrl+S - Save
    if (e.ctrlKey && e.key === 's') {
        e.preventDefault();
        saveCutscene();
    }
}

// UI State Management
function handleEnterCreator(data) {
    document.getElementById('minimal-ui').classList.remove('hidden');
    
    if (data && data.savedCutscenes) {
        savedCutscenes = data.savedCutscenes;
    }
}

function handleExitCreator() {
    document.getElementById('minimal-ui').classList.add('hidden');
    document.getElementById('full-ui').classList.add('hidden');
}

function showFullUI(data) {
    document.getElementById('minimal-ui').classList.add('hidden');
    document.getElementById('full-ui').classList.remove('hidden');
    
    if (data && data.savedCutscenes) {
        savedCutscenes = data.savedCutscenes;
        renderSavedList();
    }
    
    updateStats();
}

function hideFullUI() {
    document.getElementById('full-ui').classList.add('hidden');
    document.getElementById('minimal-ui').classList.remove('hidden');
}

// Freecam Position Updates
function updateFreecamPosition(coords, rot, fov) {
    // Mini UI
    const miniPos = document.getElementById('miniPos');
    const miniFov = document.getElementById('miniFov');
    
    if (miniPos) {
        miniPos.textContent = `${coords.x.toFixed(1)}, ${coords.y.toFixed(1)}, ${coords.z.toFixed(1)}`;
    }
    if (miniFov) {
        miniFov.textContent = fov.toFixed(0);
    }
    
    // Full UI
    const camX = document.getElementById('camX');
    const camY = document.getElementById('camY');
    const camZ = document.getElementById('camZ');
    const camFov = document.getElementById('camFov');
    
    if (camX) camX.textContent = coords.x.toFixed(2);
    if (camY) camY.textContent = coords.y.toFixed(2);
    if (camZ) camZ.textContent = coords.z.toFixed(2);
    if (camFov) camFov.textContent = fov.toFixed(0);
}

// Saved Cutscenes List
function renderSavedList() {
    const list = document.getElementById('savedList');
    if (!list) return;
    
    if (savedCutscenes.length === 0) {
        list.innerHTML = '<div class="empty-msg">No saved cutscenes</div>';
        return;
    }
    
    list.innerHTML = savedCutscenes.map(cs => `
        <div class="saved-item">
            <div class="saved-item-name">${escapeHtml(cs.name)}</div>
            <div class="saved-item-actions">
                <button class="btn btn-primary btn-small" onclick="loadCutscene('${escapeHtml(cs.name)}')">Load</button>
                <button class="btn btn-danger btn-small" onclick="deleteCutscene('${escapeHtml(cs.name)}')">Delete</button>
            </div>
        </div>
    `).join('');
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Save/Load/Delete
function saveCutscene() {
    const name = document.getElementById('cutsceneName').value.trim();
    
    if (!name) {
        showNotification('Please enter a cutscene name', 'warning');
        return;
    }
    
    sendNUI('saveCutscene', { name })
        .then(response => {
            if (response.success) {
                showNotification(`Cutscene "${name}" saved successfully!`, 'success');
            } else {
                showNotification('Failed to save cutscene', 'danger');
            }
        });
}

function loadCutscene(name) {
    sendNUI('loadCutscene', { name })
        .then(response => {
            if (response.success) {
                showNotification(`Cutscene "${name}" loaded!`, 'success');
                document.getElementById('cutsceneName').value = name;
            } else {
                showNotification('Failed to load cutscene', 'danger');
            }
        });
}

function deleteCutscene(name) {
    if (!confirm(`Delete cutscene "${name}"? This cannot be undone!`)) {
        return;
    }
    
    sendNUI('deleteCutscene', { name })
        .then(response => {
            if (response.success) {
                showNotification(`Cutscene "${name}" deleted`, 'success');
            } else {
                showNotification('Failed to delete cutscene', 'danger');
            }
        });
}

function handleCutsceneSaved(updatedList) {
    savedCutscenes = updatedList;
    renderSavedList();
}

function handleCutsceneLoaded(cutscene) {
    updateStats();
}

function handleCutsceneDeleted(updatedList) {
    savedCutscenes = updatedList;
    renderSavedList();
}

// Export
function exportCutscene() {
    const name = document.getElementById('cutsceneName').value.trim();
    if (!name) {
        showNotification('Please enter a cutscene name', 'warning');
        return;
    }
    
    showNotification('Export functionality - check server console', 'info');
    sendNUI('exportCutscene', { name });
}

// Context Menu
function showContextMenu(options) {
    const menu = document.getElementById('contextMenu');
    const items = document.getElementById('contextItems');
    
    if (!menu || !items) return;
    
    // Store actions globally
    contextMenuActions = options.map(opt => opt.action);
    
    items.innerHTML = options.map((opt, i) => 
        `<div class="context-item" onclick="selectContextOption(${i})">${escapeHtml(opt.label)}</div>`
    ).join('');
    
    menu.classList.remove('hidden');
    
    // Position at cursor (approximate center if no event)
    menu.style.left = '50%';
    menu.style.top = '50%';
    menu.style.transform = 'translate(-50%, -50%)';
}

function selectContextOption(index) {
    const menu = document.getElementById('contextMenu');
    if (menu) menu.classList.add('hidden');
    
    sendNUI('contextMenuAction', { actionIndex: index });
}

// Close context menu on outside click
document.addEventListener('click', (e) => {
    const menu = document.getElementById('contextMenu');
    if (menu && !menu.classList.contains('hidden') && !menu.contains(e.target)) {
        menu.classList.add('hidden');
    }
});

// Spawn Menu
function showSpawnMenu(type) {
    currentState.spawnType = type;
    
    const modal = document.getElementById('spawnMenu');
    const title = document.getElementById('spawnTitle');
    const modelSelect = document.getElementById('spawnModel');
    
    if (!modal || !title || !modelSelect) return;
    
    const typeLabel = type.charAt(0).toUpperCase() + type.slice(1);
    title.textContent = `Add ${typeLabel}`;
    
    // Populate models based on type
    if (type === 'actor') {
        modelSelect.innerHTML = `
            <option value="mp_m_freemode_01">Male Freemode</option>
            <option value="mp_f_freemode_01">Female Freemode</option>
            <option value="a_m_y_business_01">Business Male</option>
            <option value="a_f_y_business_01">Business Female</option>
            <option value="a_m_y_hipster_01">Hipster Male</option>
            <option value="a_f_y_hipster_01">Hipster Female</option>
            <option value="a_m_y_beach_01">Beach Male</option>
            <option value="s_m_y_cop_01">Police Officer</option>
            <option value="s_f_y_cop_01">Police Officer Female</option>
        `;
    } else if (type === 'prop') {
        modelSelect.innerHTML = `
            <option value="prop_cs_beer_bot_01">Beer Bottle</option>
            <option value="prop_amb_phone">Phone</option>
            <option value="prop_cs_script_bottle">Script Bottle</option>
            <option value="prop_ld_chair_01">Chair</option>
            <option value="prop_table_01">Table</option>
            <option value="prop_bench_01a">Bench</option>
            <option value="prop_bin_01a">Trash Bin</option>
        `;
    } else if (type === 'vehicle') {
        modelSelect.innerHTML = `
            <option value="adder">Adder (Supercar)</option>
            <option value="zentorno">Zentorno (Supercar)</option>
            <option value="t20">T20 (Supercar)</option>
            <option value="turismor">Turismo R</option>
            <option value="police">Police Cruiser</option>
            <option value="police2">Police Buffalo</option>
            <option value="ambulance">Ambulance</option>
            <option value="firetruk">Fire Truck</option>
            <option value="baller">Baller (SUV)</option>
            <option value="sultan">Sultan</option>
        `;
    }
    
    modal.classList.remove('hidden');
}

function confirmSpawnEntity() {
    const name = document.getElementById('spawnName').value.trim() || 'Unnamed';
    const model = document.getElementById('spawnModel').value;
    const type = currentState.spawnType;
    
    if (!model) {
        showNotification('Please select a model', 'warning');
        return;
    }
    
    if (type === 'actor') {
        sendNUI('spawnActor', { name, model });
    } else if (type === 'prop') {
        sendNUI('spawnProp', { name, model });
    } else if (type === 'vehicle') {
        sendNUI('spawnVehicle', { name, model });
    }
    
    document.getElementById('spawnName').value = '';
    hideModal('spawnMenu');
    updateStats();
}

// Vec4 Editor
function showVec4Editor(data) {
    currentState.type = data.type;
    currentState.index = data.index;
    
    document.getElementById('vec4X').value = data.x.toFixed(2);
    document.getElementById('vec4Y').value = data.y.toFixed(2);
    document.getElementById('vec4Z').value = data.z.toFixed(2);
    document.getElementById('vec4W').value = data.w.toFixed(2);
    
    document.getElementById('vec4Editor').classList.remove('hidden');
}

function confirmVec4Update() {
    const x = parseFloat(document.getElementById('vec4X').value);
    const y = parseFloat(document.getElementById('vec4Y').value);
    const z = parseFloat(document.getElementById('vec4Z').value);
    const w = parseFloat(document.getElementById('vec4W').value);
    
    sendNUI('updateVec4', {
        type: currentState.type,
        index: currentState.index,
        x, y, z, w
    });
    
    hideModal('vec4Editor');
}

// Outfit Editor
function showOutfitEditor(index, outfit) {
    currentState.index = index;
    const container = document.getElementById('outfitComponents');
    
    if (!container) return;
    
    const components = [
        'Face', 'Mask', 'Hair', 'Torso', 'Legs', 'Bag', 
        'Shoes', 'Accessories', 'Undershirt', 'Armor', 'Decals', 'Tops'
    ];
    
    container.innerHTML = components.map((name, id) => {
        const comp = outfit?.components?.[id] || {drawable: 0, texture: 0};
        return `
            <div class="outfit-item">
                <label>${id}: ${name}</label>
                <div class="outfit-inputs">
                    <input type="number" class="input-field comp-drawable" data-id="${id}" 
                           value="${comp.drawable}" min="0" placeholder="Drawable">
                    <input type="number" class="input-field comp-texture" data-id="${id}" 
                           value="${comp.texture}" min="0" placeholder="Texture">
                </div>
            </div>
        `;
    }).join('');
    
    document.getElementById('outfitEditor').classList.remove('hidden');
}

function confirmOutfitUpdate() {
    const components = {};
    const props = {};
    
    document.querySelectorAll('.comp-drawable').forEach(input => {
        const id = input.dataset.id;
        const drawable = parseInt(input.value) || 0;
        const textureInput = document.querySelector(`.comp-texture[data-id="${id}"]`);
        const texture = parseInt(textureInput?.value) || 0;
        components[id] = { drawable, texture };
    });
    
    sendNUI('updateOutfit', {
        index: currentState.index,
        components,
        props
    });
    
    hideModal('outfitEditor');
}

// Animation Menu
function showAnimationMenu(index, animation) {
    currentState.index = index;
    
    document.getElementById('animDict').value = animation?.dict || '';
    document.getElementById('animName').value = animation?.name || '';
    document.getElementById('animFlags').value = animation?.flags || 1;
    
    document.getElementById('animMenu').classList.remove('hidden');
}

function confirmAnimationSet() {
    const dict = document.getElementById('animDict').value.trim();
    const anim = document.getElementById('animName').value.trim();
    const flags = parseInt(document.getElementById('animFlags').value) || 1;
    
    if (!dict || !anim) {
        showNotification('Please enter animation dictionary and name', 'warning');
        return;
    }
    
    sendNUI('setAnimation', {
        index: currentState.index,
        dict, anim, flags
    });
    
    hideModal('animMenu');
}

// Vehicle Mods
function showVehicleModMenu(index, mods) {
    currentState.index = index;
    const container = document.getElementById('vehMods');
    
    if (!container) return;
    
    const modTypes = [
        'Spoiler', 'Front Bumper', 'Rear Bumper', 'Side Skirt', 
        'Exhaust', 'Frame', 'Grille', 'Hood', 'Fender', 'Right Fender',
        'Roof', 'Engine', 'Brakes', 'Transmission', 'Horns', 
        'Suspension', 'Armor'
    ];
    
    container.innerHTML = modTypes.map((name, id) => {
        const value = mods?.[id] || 0;
        return `
            <div class="mod-item">
                <label>${id}: ${name}</label>
                <input type="number" class="input-field mod-value" data-id="${id}" 
                       value="${value}" min="-1" max="50">
            </div>
        `;
    }).join('');
    
    document.getElementById('vehModMenu').classList.remove('hidden');
}

function confirmVehicleMods() {
    const mods = {};
    
    document.querySelectorAll('.mod-value').forEach(input => {
        mods[input.dataset.id] = parseInt(input.value) || 0;
    });
    
    sendNUI('updateVehicleMods', {
        index: currentState.index,
        mods
    });
    
    hideModal('vehModMenu');
}

// Vehicle Colors
function showVehicleColorMenu(index, colors) {
    currentState.index = index;
    
    document.getElementById('vehPrimary').value = colors?.primary || 0;
    document.getElementById('vehSecondary').value = colors?.secondary || 0;
    
    document.getElementById('vehColorMenu').classList.remove('hidden');
}

function confirmVehicleColors() {
    const primary = parseInt(document.getElementById('vehPrimary').value) || 0;
    const secondary = parseInt(document.getElementById('vehSecondary').value) || 0;
    
    sendNUI('updateVehicleColors', {
        index: currentState.index,
        primary, secondary
    });
    
    hideModal('vehColorMenu');
}

// Audio Menu
function showAudioMenu() {
    showNotification('Audio menu - coming soon', 'info');
}

// Update Stats
function updateStats() {
    // This would be populated from game data
    // For now, placeholder
}

// Modal Management
function hideModal(id) {
    const modal = document.getElementById(id);
    if (modal) modal.classList.add('hidden');
}

// Notifications
function showNotification(message, type = 'info') {
    const notif = document.createElement('div');
    notif.className = 'notification';
    notif.style.cssText = `
        position: fixed;
        top: 80px;
        right: 20px;
        background: ${type === 'success' ? 'var(--success)' : 
                     type === 'danger' ? 'var(--danger)' : 
                     type === 'warning' ? 'var(--warning)' : 'var(--accent-primary)'};
        color: ${type === 'success' || type === 'danger' ? 'var(--text-primary)' : 'var(--bg-primary)'};
        padding: 12px 20px;
        border-radius: 6px;
        font-weight: 600;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        z-index: 10002;
        animation: slideIn 0.3s ease-out;
    `;
    notif.textContent = message;
    document.body.appendChild(notif);
    
    setTimeout(() => {
        notif.style.animation = 'fadeOut 0.3s ease-out';
        setTimeout(() => notif.remove(), 300);
    }, 3000);
}

// NUI Communication
function sendNUI(action, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    })
    .then(response => {
        // Ellenőrizzük hogy van-e válasz
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.text();
    })
    .then(text => {
        // Ha üres a válasz, return default object
        if (!text || text.trim() === '') {
            return { success: true };
        }
        try {
            return JSON.parse(text);
        } catch (e) {
            console.warn('Failed to parse JSON, using default response');
            return { success: true };
        }
    })
    .catch(error => {
        console.error('NUI request error:', error);
        return { success: false, error: error.message };
    });
}

function GetParentResourceName() {
    return window.location.hostname === '' ? 'll-core' : window.location.hostname;
}

// Make functions globally available
window.loadCutscene = loadCutscene;
window.deleteCutscene = deleteCutscene;
window.selectContextOption = selectContextOption;

console.log('Cutscene Creator initialized');