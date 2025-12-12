// Minimal Cutscene Creator - In-Game Focus
let currentState = {
    type: null,
    index: null,
    spawnType: null
};

let savedCutscenes = [];

// Message Handler
window.addEventListener('message', (e) => {
    const data = e.data;
    
    if (data.action === 'enterCreator') {
        document.getElementById('minimal-ui').classList.remove('hidden');
        if (data.data && data.data.savedCutscenes) {
            savedCutscenes = data.data.savedCutscenes;
        }
    } else if (data.action === 'exitCreator') {
        document.getElementById('minimal-ui').classList.add('hidden');
        document.getElementById('full-ui').classList.add('hidden');
    } else if (data.action === 'showUI') {
        document.getElementById('minimal-ui').classList.add('hidden');
        document.getElementById('full-ui').classList.remove('hidden');
        if (data.data && data.data.savedCutscenes) {
            savedCutscenes = data.data.savedCutscenes;
            renderSavedList();
        }
    } else if (data.action === 'hideUI') {
        document.getElementById('full-ui').classList.add('hidden');
        document.getElementById('minimal-ui').classList.remove('hidden');
    } else if (data.action === 'updateFreecamPos') {
        updatePositionDisplay(data.coords, data.rot, data.fov);
    } else if (data.action === 'showContextMenu') {
        showContextMenu(data.options);
    } else if (data.action === 'showSpawnMenu') {
        showSpawnMenu(data.spawnType);
    } else if (data.action === 'showVec4Editor') {
        showVec4Editor(data.data);
    } else if (data.action === 'showOutfitEditor') {
        showOutfitEditor(data.index, data.outfit);
    } else if (data.action === 'showAnimationMenu') {
        showAnimationMenu(data.index, data.animation);
    } else if (data.action === 'showVehicleModMenu') {
        showVehicleModMenu(data.index, data.mods);
    } else if (data.action === 'showVehicleColorMenu') {
        showVehicleColorMenu(data.index, data.colors);
    } else if (data.action === 'cutsceneSaved') {
        savedCutscenes = data.savedCutscenes;
        renderSavedList();
    }
});

// Event Listeners
document.addEventListener('DOMContentLoaded', () => {
    // Expand UI
    document.getElementById('expandBtn')?.addEventListener('click', () => {
        sendNUI('closeUI'); // Actually expands by triggering toggle
    });
    
    // Collapse UI
    document.getElementById('collapseBtn')?.addEventListener('click', () => {
        sendNUI('closeUI');
    });
    
    // Save
    document.getElementById('saveBtn')?.addEventListener('click', saveCutscene);
    
    // Spawn Confirmations
    document.getElementById('confirmSpawn')?.addEventListener('click', confirmSpawn);
    document.getElementById('cancelSpawn')?.addEventListener('click', () => hideModal('spawnMenu'));
    
    // Vec4 Editor
    document.getElementById('confirmVec4')?.addEventListener('click', confirmVec4);
    document.getElementById('cancelVec4')?.addEventListener('click', () => hideModal('vec4Editor'));
    
    // Outfit Editor
    document.getElementById('confirmOutfit')?.addEventListener('click', confirmOutfit);
    document.getElementById('cancelOutfit')?.addEventListener('click', () => hideModal('outfitEditor'));
    
    // Animation Menu
    document.getElementById('confirmAnim')?.addEventListener('click', confirmAnimation);
    document.getElementById('cancelAnim')?.addEventListener('click', () => hideModal('animMenu'));
    
    // Vehicle Mod Menu
    document.getElementById('confirmVehMod')?.addEventListener('click', confirmVehicleMod);
    document.getElementById('cancelVehMod')?.addEventListener('click', () => hideModal('vehModMenu'));
    
    // Vehicle Color Menu
    document.getElementById('confirmVehColor')?.addEventListener('click', confirmVehicleColor);
    document.getElementById('cancelVehColor')?.addEventListener('click', () => hideModal('vehColorMenu'));
});

// Update Position Display
function updatePositionDisplay(coords, rot, fov) {
    // Mini UI
    document.getElementById('miniPos').textContent = 
        `${coords.x.toFixed(1)}, ${coords.y.toFixed(1)}, ${coords.z.toFixed(1)}`;
    document.getElementById('miniFov').textContent = fov.toFixed(0);
    
    // Full UI
    document.getElementById('camX').textContent = coords.x.toFixed(2);
    document.getElementById('camY').textContent = coords.y.toFixed(2);
    document.getElementById('camZ').textContent = coords.z.toFixed(2);
    document.getElementById('camFov').textContent = fov.toFixed(0);
}

// Saved List
function renderSavedList() {
    const list = document.getElementById('savedList');
    if (!list) return;
    
    if (savedCutscenes.length === 0) {
        list.innerHTML = '<div class="empty-msg">No saved cutscenes</div>';
        return;
    }
    
    list.innerHTML = savedCutscenes.map(cs => `
        <div class="saved-item">
            <div class="saved-item-name">${cs.name}</div>
            <div class="saved-item-actions">
                <button class="btn btn-primary btn-small" onclick="loadCutscene('${cs.name}')">Load</button>
                <button class="btn btn-danger btn-small" onclick="deleteCutscene('${cs.name}')">Delete</button>
            </div>
        </div>
    `).join('');
}

// Save/Load
function saveCutscene() {
    const name = document.getElementById('cutsceneName').value.trim();
    if (!name) {
        alert('Please enter a cutscene name');
        return;
    }
    
    sendNUI('saveCutscene', { name });
}

function loadCutscene(name) {
    sendNUI('loadCutscene', { name });
}

function deleteCutscene(name) {
    if (confirm(`Delete "${name}"?`)) {
        sendNUI('deleteCutscene', { name });
    }
}

// Context Menu
function showContextMenu(options) {
    const menu = document.getElementById('contextMenu');
    const items = document.getElementById('contextItems');
    
    items.innerHTML = options.map((opt, i) => 
        `<div class="context-item" onclick="selectContextOption(${i})">${opt.label}</div>`
    ).join('');
    
    // Store actions globally
    window.contextActions = options.map(o => o.action);
    
    menu.classList.remove('hidden');
    
    // Position at cursor
    const x = event.clientX || window.innerWidth / 2;
    const y = event.clientY || window.innerHeight / 2;
    menu.style.left = x + 'px';
    menu.style.top = y + 'px';
}

function selectContextOption(index) {
    document.getElementById('contextMenu').classList.add('hidden');
    
    if (window.contextActions && window.contextActions[index]) {
        sendNUI('contextMenuAction', { actionIndex: index });
    }
}

// Close context menu on click outside
document.addEventListener('click', (e) => {
    const menu = document.getElementById('contextMenu');
    if (!menu?.classList.contains('hidden') && !menu.contains(e.target)) {
        menu.classList.add('hidden');
    }
});

// Spawn Menu
function showSpawnMenu(type) {
    currentState.spawnType = type;
    const modal = document.getElementById('spawnMenu');
    const title = document.getElementById('spawnTitle');
    const modelSelect = document.getElementById('spawnModel');
    
    title.textContent = `Add ${type.charAt(0).toUpperCase() + type.slice(1)}`;
    
    // Populate models
    if (type === 'actor') {
        modelSelect.innerHTML = `
            <option value="mp_m_freemode_01">Male Freemode</option>
            <option value="mp_f_freemode_01">Female Freemode</option>
            <option value="a_m_y_business_01">Business Male</option>
            <option value="a_f_y_business_01">Business Female</option>
            <option value="a_m_y_hipster_01">Hipster Male</option>
        `;
    } else if (type === 'prop') {
        modelSelect.innerHTML = `
            <option value="prop_cs_beer_bot_01">Beer Bottle</option>
            <option value="prop_amb_phone">Phone</option>
            <option value="prop_cs_script_bottle">Bottle</option>
            <option value="prop_ld_chair_01">Chair</option>
        `;
    } else if (type === 'vehicle') {
        modelSelect.innerHTML = `
            <option value="adder">Adder</option>
            <option value="zentorno">Zentorno</option>
            <option value="t20">T20</option>
            <option value="police">Police</option>
            <option value="ambulance">Ambulance</option>
        `;
    }
    
    modal.classList.remove('hidden');
}

function confirmSpawn() {
    const name = document.getElementById('spawnName').value.trim() || 'Unnamed';
    const model = document.getElementById('spawnModel').value;
    const type = currentState.spawnType;
    
    if (type === 'actor') {
        sendNUI('spawnActor', { name, model });
    } else if (type === 'prop') {
        sendNUI('spawnProp', { name, model });
    } else if (type === 'vehicle') {
        sendNUI('spawnVehicle', { name, model });
    }
    
    document.getElementById('spawnName').value = '';
    hideModal('spawnMenu');
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

function confirmVec4() {
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
    
    const components = ['Face', 'Mask', 'Hair', 'Torso', 'Legs', 'Bag', 'Shoes', 'Accessories', 'Undershirt', 'Armor', 'Decals', 'Tops'];
    
    container.innerHTML = components.map((name, id) => {
        const comp = outfit?.components?.[id] || {drawable: 0, texture: 0};
        return `
            <div class="outfit-item">
                <label>${id}: ${name}</label>
                <div class="outfit-inputs">
                    <input type="number" class="input-field comp-drawable" data-id="${id}" value="${comp.drawable}" min="0">
                    <input type="number" class="input-field comp-texture" data-id="${id}" value="${comp.texture}" min="0">
                </div>
            </div>
        `;
    }).join('');
    
    document.getElementById('outfitEditor').classList.remove('hidden');
}

function confirmOutfit() {
    const components = {};
    document.querySelectorAll('.comp-drawable').forEach(input => {
        const id = input.dataset.id;
        const drawable = parseInt(input.value);
        const texture = parseInt(document.querySelector(`.comp-texture[data-id="${id}"]`).value);
        components[id] = { drawable, texture };
    });
    
    sendNUI('updateOutfit', {
        index: currentState.index,
        components,
        props: {} // Add props if needed
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

function confirmAnimation() {
    const dict = document.getElementById('animDict').value.trim();
    const anim = document.getElementById('animName').value.trim();
    const flags = parseInt(document.getElementById('animFlags').value);
    
    if (!dict || !anim) {
        alert('Please enter animation dict and name');
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
    
    const modTypes = ['Spoiler', 'Front Bumper', 'Rear Bumper', 'Side Skirt', 'Exhaust', 'Frame', 'Grille', 'Hood', 'Fender', 'Right Fender', 'Roof', 'Engine', 'Brakes', 'Transmission', 'Horns', 'Suspension', 'Armor'];
    
    container.innerHTML = modTypes.map((name, id) => {
        const value = mods?.[id] || 0;
        return `
            <div class="mod-item">
                <label>${id}: ${name}</label>
                <input type="number" class="input-field mod-value" data-id="${id}" value="${value}" min="-1" max="50">
            </div>
        `;
    }).join('');
    
    document.getElementById('vehModMenu').classList.remove('hidden');
}

function confirmVehicleMod() {
    const mods = {};
    document.querySelectorAll('.mod-value').forEach(input => {
        mods[input.dataset.id] = parseInt(input.value);
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

function confirmVehicleColor() {
    const primary = parseInt(document.getElementById('vehPrimary').value);
    const secondary = parseInt(document.getElementById('vehSecondary').value);
    
    sendNUI('updateVehicleColors', {
        index: currentState.index,
        primary, secondary
    });
    
    hideModal('vehColorMenu');
}

// Helper Functions
function hideModal(id) {
    document.getElementById(id)?.classList.add('hidden');
}

function sendNUI(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).catch(() => {});
}

function GetParentResourceName() {
    return window.location.hostname === '' ? 'll-core' : window.location.hostname;
}

// Make functions global
window.loadCutscene = loadCutscene;
window.deleteCutscene = deleteCutscene;
window.selectContextOption = selectContextOption;

console.log('Cutscene Creator UI loaded');

function renderActorTracks() {
    const container = document.getElementById('actorTracks');
    const labels = document.getElementById('actorLabels');
    
    container.innerHTML = '';
    labels.innerHTML = '';
    
    currentCutscene.tracks.actors.forEach((actor, actorIndex) => {
        // Label
        const label = document.createElement('div');
        label.className = 'track-label';
        label.textContent = actor.name || `Actor ${actorIndex + 1}`;
        labels.appendChild(label);
        
        // Track
        const track = document.createElement('div');
        track.className = 'track actor-track';
        track.dataset.track = `actor-${actorIndex}`;
        
        const content = document.createElement('div');
        content.className = 'track-content';
        
        actor.keyframes.forEach((keyframe, kfIndex) => {
            const kf = createKeyframeElement(keyframe, `actor-${actorIndex}`, kfIndex);
            content.appendChild(kf);
        });
        
        track.appendChild(content);
        container.appendChild(track);
    });
}

function renderPropTracks() {
    const container = document.getElementById('propTracks');
    const labels = document.getElementById('propLabels');
    
    container.innerHTML = '';
    labels.innerHTML = '';
    
    currentCutscene.tracks.props.forEach((prop, propIndex) => {
        // Label
        const label = document.createElement('div');
        label.className = 'track-label';
        label.textContent = prop.name || `Prop ${propIndex + 1}`;
        labels.appendChild(label);
        
        // Track
        const track = document.createElement('div');
        track.className = 'track prop-track';
        track.dataset.track = `prop-${propIndex}`;
        
        const content = document.createElement('div');
        content.className = 'track-content';
        
        prop.keyframes.forEach((keyframe, kfIndex) => {
            const kf = createKeyframeElement(keyframe, `prop-${propIndex}`, kfIndex);
            content.appendChild(kf);
        });
        
        track.appendChild(content);
        container.appendChild(track);
    });
}

function renderAudioTrack() {
    const track = document.getElementById('audioTrack');
    track.innerHTML = '';
    
    currentCutscene.tracks.audio.forEach((audio, index) => {
        const kf = createKeyframeElement({time: audio.time}, 'audio', index);
        kf.title = audio.soundName;
        track.appendChild(kf);
    });
}

function createKeyframeElement(keyframe, trackType, index) {
    const kf = document.createElement('div');
    kf.className = 'keyframe';
    kf.dataset.track = trackType;
    kf.dataset.index = index;
    
    const position = (keyframe.time / currentCutscene.duration) * 100;
    kf.style.left = `${position}%`;
    
    kf.addEventListener('click', (e) => {
        e.stopPropagation();
        selectKeyframe(trackType, index);
    });
    
    // Make draggable
    kf.draggable = true;
    kf.addEventListener('dragstart', handleKeyframeDragStart);
    kf.addEventListener('dragend', handleKeyframeDragEnd);
    
    return kf;
}

function selectKeyframe(trackType, index) {
    // Remove previous selection
    document.querySelectorAll('.keyframe').forEach(kf => kf.classList.remove('selected'));
    
    // Select new
    const kf = document.querySelector(`.keyframe[data-track="${trackType}"][data-index="${index}"]`);
    if (kf) {
        kf.classList.add('selected');
        selectedTrack = trackType;
        selectedKeyframe = index;
        
        // Show properties
        showKeyframeProperties(trackType, index);
    }
}

function showKeyframeProperties(trackType, index) {
    const propsPanel = document.getElementById('keyframeProperties');
    
    if (trackType === 'camera') {
        const keyframe = currentCutscene.tracks.camera[index];
        propsPanel.innerHTML = `
            <h2>Camera Keyframe</h2>
            <div class="property-group">
                <label>Time (ms)</label>
                <input type="number" value="${keyframe.time}" onchange="updateKeyframeTime('camera', ${index}, this.value)">
            </div>
            <div class="property-group">
                <label>FOV</label>
                <input type="number" value="${keyframe.fov}" min="10" max="130" onchange="updateKeyframeFOV('camera', ${index}, this.value)">
            </div>
            <div class="property-group">
                <label>Easing</label>
                <select onchange="updateKeyframeEasing('camera', ${index}, this.value)">
                    <option value="linear" ${keyframe.easing === 'linear' ? 'selected' : ''}>Linear</option>
                    <option value="easeIn" ${keyframe.easing === 'easeIn' ? 'selected' : ''}>Ease In</option>
                    <option value="easeOut" ${keyframe.easing === 'easeOut' ? 'selected' : ''}>Ease Out</option>
                    <option value="easeInOut" ${keyframe.easing === 'easeInOut' ? 'selected' : ''}>Ease In/Out</option>
                </select>
            </div>
        `;
    }
}

function deleteKeyframe(index) {
    if (selectedTrack === 'camera') {
        currentCutscene.tracks.camera.splice(index, 1);
    }
    
    selectedKeyframe = null;
    selectedTrack = null;
    renderTimeline();
}

let draggedKeyframe = null;

function handleKeyframeDragStart(e) {
    draggedKeyframe = e.target;
    e.dataTransfer.effectAllowed = 'move';
}

function handleKeyframeDragEnd(e) {
    // Calculate new time based on position
    const track = e.target.closest('.track-content');
    const rect = track.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const percentage = x / rect.width;
    const newTime = Math.max(0, Math.min(currentCutscene.duration, percentage * currentCutscene.duration));
    
    const trackType = e.target.dataset.track;
    const index = parseInt(e.target.dataset.index);
    
    // Update keyframe time
    if (trackType === 'camera') {
        currentCutscene.tracks.camera[index].time = Math.round(newTime);
    } else if (trackType.startsWith('actor')) {
        const actorIndex = parseInt(trackType.split('-')[1]);
        currentCutscene.tracks.actors[actorIndex].keyframes[index].time = Math.round(newTime);
    }
    
    renderTimeline();
    draggedKeyframe = null;
}

function formatTime(ms) {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const milliseconds = ms % 1000;
    
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}.${milliseconds.toString().padStart(3, '0')}`;
}

function showNotification(message, type = 'info') {
    // Simple notification system
    const notif = document.createElement('div');
    notif.style.cssText = `
        position: fixed;
        top: 80px;
        right: 20px;
        background: ${type === 'success' ? 'var(--success)' : type === 'error' ? 'var(--danger)' : 'var(--accent-primary)'};
        color: ${type === 'success' || type === 'error' ? 'var(--text-primary)' : 'var(--bg-primary)'};
        padding: 12px 20px;
        border-radius: 6px;
        font-weight: 600;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        z-index: 10001;
        animation: fadeIn 0.3s ease-out;
    `;
    notif.textContent = message;
    document.body.appendChild(notif);
    
    setTimeout(() => {
        notif.style.animation = 'fadeOut 0.3s ease-out';
        setTimeout(() => notif.remove(), 300);
    }, 3000);
}

function sendNUI(action, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    })
    .then(response => response.json())
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
window.playCutsceneByName = playCutsceneByName;
window.updateKeyframeTime = (track, index, value) => {
    currentCutscene.tracks[track][index].time = parseInt(value);
    renderTimeline();
};
window.updateKeyframeFOV = (track, index, value) => {
    currentCutscene.tracks[track][index].fov = parseFloat(value);
};
window.updateKeyframeEasing = (track, index, value) => {
    currentCutscene.tracks[track][index].easing = value;
};

console.log('Advanced Cutscene Creator initialized');