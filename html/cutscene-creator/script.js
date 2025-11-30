// Cutscene Creator JavaScript
let cutsceneData = {
    name: "",
    duration: 30000,
    timeline: [],
    npcs: [],
    audio: []
};

let config = {
    components: {},
    props: {},
    animations: []
};

let selectedNPC = null;
let isInitialized = false;

// Message listener
window.addEventListener('message', (event) => {
    const data = event.data;
    
    try {
        if (data.action === 'openCreator') {
            console.log('Opening creator');
            cutsceneData = data.data.cutscene || cutsceneData;
            config = data.data.config || config;
            
            document.getElementById('creator-container').classList.remove('hidden');
            
            if (!isInitialized) {
                initializeUI();
                isInitialized = true;
            }
            
            initializeComponents();
            updateUI();
        } else if (data.action === 'closeCreator') {
            console.log('Closing creator');
            document.getElementById('creator-container').classList.add('hidden');
            selectedNPC = null;
        } else if (data.action === 'updateCutscene') {
            console.log('Updating cutscene');
            cutsceneData = data.data;
            updateUI();
        }
    } catch (error) {
        console.error('Message handler error:', error);
    }
});

function initializeUI() {
    console.log('Initializing UI');
    
    // Close button
    const closeBtn = document.getElementById('closeBtn');
    if (closeBtn) {
        closeBtn.onclick = function(e) {
            e.preventDefault();
            sendNUI('closeCreator', {});
        };
    }
    
    // Add Keyframe button
    const addKeyframeBtn = document.getElementById('addKeyframeBtn');
    if (addKeyframeBtn) {
        addKeyframeBtn.onclick = function(e) {
            e.preventDefault();
            addKeyframe();
        };
    }
    
    // Add NPC button
    const addNPCBtn = document.getElementById('addNPCBtn');
    if (addNPCBtn) {
        addNPCBtn.onclick = function(e) {
            e.preventDefault();
            addNPC();
        };
    }
    
    // Preview button
    const previewBtn = document.getElementById('previewBtn');
    if (previewBtn) {
        previewBtn.onclick = function(e) {
            e.preventDefault();
            previewCutscene();
        };
    }
    
    // Save button
    const saveCutsceneBtn = document.getElementById('saveCutsceneBtn');
    if (saveCutsceneBtn) {
        saveCutsceneBtn.onclick = function(e) {
            e.preventDefault();
            saveCutscene();
        };
    }
    
    // Load button
    const loadCutsceneBtn = document.getElementById('loadCutsceneBtn');
    if (loadCutsceneBtn) {
        loadCutsceneBtn.onclick = function(e) {
            e.preventDefault();
            loadCutscene();
        };
    }
    
    // Save NPC button
    const saveNPCBtn = document.getElementById('saveNPCBtn');
    if (saveNPCBtn) {
        saveNPCBtn.onclick = function(e) {
            e.preventDefault();
            saveNPCClothing();
        };
    }
    
    // Cancel NPC button
    const cancelNPCBtn = document.getElementById('cancelNPCBtn');
    if (cancelNPCBtn) {
        cancelNPCBtn.onclick = function(e) {
            e.preventDefault();
            cancelNPCEdit();
        };
    }
    
    console.log('UI initialized');
}

function initializeComponents() {
    console.log('Initializing components');
    
    // Components list
    const componentsList = document.getElementById('componentsList');
    if (componentsList) {
        componentsList.innerHTML = '';
        
        for (const [id, name] of Object.entries(config.components || {})) {
            const div = document.createElement('div');
            div.className = 'component-item';
            div.innerHTML = `
                <label>${name}</label>
                <div class="component-inputs">
                    <input type="number" class="component-drawable" data-id="${id}" placeholder="Drawable" min="0" value="0">
                    <input type="number" class="component-texture" data-id="${id}" placeholder="Texture" min="0" value="0">
                </div>
            `;
            componentsList.appendChild(div);
        }
    }
    
    // Props list
    const propsList = document.getElementById('propsList');
    if (propsList) {
        propsList.innerHTML = '';
        
        for (const [id, name] of Object.entries(config.props || {})) {
            const div = document.createElement('div');
            div.className = 'prop-item';
            div.innerHTML = `
                <label>${name}</label>
                <div class="component-inputs">
                    <input type="number" class="prop-drawable" data-id="${id}" placeholder="Drawable" min="-1" value="-1">
                    <input type="number" class="prop-texture" data-id="${id}" placeholder="Texture" min="0" value="0">
                </div>
            `;
            propsList.appendChild(div);
        }
    }
    
    // Animations
    const animSelect = document.getElementById('npcAnimation');
    if (animSelect) {
        animSelect.innerHTML = '<option value="">Nincs</option>';
        (config.animations || []).forEach(anim => {
            const option = document.createElement('option');
            option.value = anim;
            option.textContent = anim;
            animSelect.appendChild(option);
        });
    }
    
    console.log('Components initialized');
}

function updateUI() {
    console.log('Updating UI');
    
    // Update inputs
    const nameInput = document.getElementById('cutsceneName');
    const durationInput = document.getElementById('cutsceneDuration');
    
    if (nameInput) nameInput.value = cutsceneData.name || '';
    if (durationInput) durationInput.value = cutsceneData.duration || 30000;
    
    updateTimelineUI();
    updateNPCListUI();
}

function updateTimelineUI() {
    const timeline = document.getElementById('timeline');
    if (!timeline) return;
    
    timeline.innerHTML = '';
    
    (cutsceneData.timeline || []).forEach((keyframe, index) => {
        const div = document.createElement('div');
        div.className = 'timeline-keyframe';
        div.innerHTML = `
            <strong>Keyframe ${index + 1}</strong><br>
            Idő: ${keyframe.time}ms<br>
            Kamera: (${keyframe.camera.x.toFixed(2)}, ${keyframe.camera.y.toFixed(2)}, ${keyframe.camera.z.toFixed(2)})
        `;
        timeline.appendChild(div);
    });
}

function updateNPCListUI() {
    const npcList = document.getElementById('npcList');
    if (!npcList) return;
    
    npcList.innerHTML = '';
    
    (cutsceneData.npcs || []).forEach((npc, index) => {
        const div = document.createElement('div');
        div.className = 'npc-item';
        div.innerHTML = `
            <span>NPC ${index + 1} - ${npc.model}</span>
            <div class="npc-item-actions">
                <button class="btn btn-primary btn-small" onclick="editNPC(${index})">Szerkeszt</button>
                <button class="btn btn-danger btn-small" onclick="removeNPC(${index})">Törlés</button>
            </div>
        `;
        npcList.appendChild(div);
    });
}

function addKeyframe() {
    console.log('Adding keyframe');
    
    sendNUI('addKeyframe', {
        time: cutsceneData.timeline.length * 1000
    }).then(data => {
        if (data.success) {
            cutsceneData.timeline.push(data.keyframe);
            updateTimelineUI();
            console.log('Keyframe added');
        }
    }).catch(err => console.error('Add keyframe error:', err));
}

function addNPC() {
    console.log('Adding NPC');
    
    const model = prompt("Model név (pl: mp_m_freemode_01):", "mp_m_freemode_01");
    if (!model) return;
    
    sendNUI('addNPC', { model }).then(data => {
        if (data.success) {
            cutsceneData.npcs.push(data.npc);
            updateNPCListUI();
            console.log('NPC added:', data.npcId);
        } else {
            alert('Hiba: ' + (data.error || 'Ismeretlen hiba'));
        }
    }).catch(err => {
        console.error('Add NPC error:', err);
        alert('Hiba az NPC hozzáadásakor!');
    });
}

function editNPC(npcId) {
    console.log('Editing NPC:', npcId);
    
    selectedNPC = npcId;
    const npc = cutsceneData.npcs[npcId];
    
    if (!npc) {
        console.error('NPC not found:', npcId);
        return;
    }
    
    // Show editor
    const editor = document.getElementById('npcEditor');
    if (editor) {
        editor.classList.remove('hidden');
    }
    
    // Set model
    const modelInput = document.getElementById('npcModel');
    if (modelInput) {
        modelInput.value = npc.model || '';
    }
    
    // Load clothing
    if (npc.clothing && npc.clothing.components) {
        for (const [id, data] of Object.entries(npc.clothing.components)) {
            const drawable = document.querySelector(`.component-drawable[data-id="${id}"]`);
            const texture = document.querySelector(`.component-texture[data-id="${id}"]`);
            if (drawable) drawable.value = data.drawable || 0;
            if (texture) texture.value = data.texture || 0;
        }
    }
    
    if (npc.clothing && npc.clothing.props) {
        for (const [id, data] of Object.entries(npc.clothing.props)) {
            const drawable = document.querySelector(`.prop-drawable[data-id="${id}"]`);
            const texture = document.querySelector(`.prop-texture[data-id="${id}"]`);
            if (drawable) drawable.value = data.drawable || -1;
            if (texture) texture.value = data.texture || 0;
        }
    }
}

function removeNPC(npcId) {
    console.log('Removing NPC:', npcId);
    
    if (!confirm('Biztosan törlöd ezt az NPC-t?')) return;
    
    sendNUI('removeNPC', { npcId }).then(data => {
        if (data.success) {
            cutsceneData.npcs.splice(npcId, 1);
            updateNPCListUI();
            console.log('NPC removed');
        }
    }).catch(err => console.error('Remove NPC error:', err));
}

function saveNPCClothing() {
    console.log('Saving NPC clothing');
    
    if (selectedNPC === null) {
        console.error('No NPC selected');
        return;
    }
    
    const clothing = {
        components: {},
        props: {}
    };
    
    // Collect components
    document.querySelectorAll('.component-drawable').forEach(input => {
        const id = input.dataset.id;
        const drawable = parseInt(input.value) || 0;
        const textureInput = document.querySelector(`.component-texture[data-id="${id}"]`);
        const texture = textureInput ? parseInt(textureInput.value) || 0 : 0;
        
        clothing.components[id] = { drawable, texture };
    });
    
    // Collect props
    document.querySelectorAll('.prop-drawable').forEach(input => {
        const id = input.dataset.id;
        const drawable = parseInt(input.value) || -1;
        const textureInput = document.querySelector(`.prop-texture[data-id="${id}"]`);
        const texture = textureInput ? parseInt(textureInput.value) || 0 : 0;
        
        clothing.props[id] = { drawable, texture };
    });
    
    sendNUI('updateNPCClothing', {
        npcId: selectedNPC,
        clothing: clothing
    }).then(data => {
        if (data.success) {
            cutsceneData.npcs[selectedNPC].clothing = clothing;
            cancelNPCEdit();
            console.log('NPC clothing saved');
        }
    }).catch(err => console.error('Save NPC error:', err));
}

function cancelNPCEdit() {
    const editor = document.getElementById('npcEditor');
    if (editor) {
        editor.classList.add('hidden');
    }
    selectedNPC = null;
}

function previewCutscene() {
    console.log('Previewing cutscene');
    
    cutsceneData.name = document.getElementById('cutsceneName').value;
    cutsceneData.duration = parseInt(document.getElementById('cutsceneDuration').value);
    
    sendNUI('previewCutscene', cutsceneData)
        .catch(err => console.error('Preview error:', err));
}

function saveCutscene() {
    console.log('Saving cutscene');
    
    const name = document.getElementById('cutsceneName').value;
    const duration = parseInt(document.getElementById('cutsceneDuration').value);
    
    if (!name || name.trim() === '') {
        alert('Add meg a cutscene nevét!');
        return;
    }
    
    cutsceneData.name = name;
    cutsceneData.duration = duration || 30000;
    
    sendNUI('saveCutscene', {
        name: name,
        duration: duration,
        cutsceneData: cutsceneData
    }).then(data => {
        if (data.success) {
            alert('Cutscene sikeresen mentve!');
        } else {
            alert('Hiba: ' + (data.error || 'Ismeretlen hiba'));
        }
    }).catch(err => {
        console.error('Save error:', err);
        alert('Hiba történt a mentés során!');
    });
}

function loadCutscene() {
    console.log('Loading cutscene');
    
    const name = prompt('Cutscene név:');
    if (!name) return;
    
    sendNUI('loadCutscene', { name })
        .catch(err => console.error('Load error:', err));
}

function sendNUI(action, data) {
    return fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data || {})
    })
    .then(response => response.json())
    .catch(error => {
        console.error('NUI request error:', error);
        throw error;
    });
}

function GetParentResourceName() {
    return window.location.hostname === '' ? 'll-core' : window.location.hostname;
}

// ESC key handler
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        sendNUI('closeCreator', {});
    }
});

// Make functions globally available
window.editNPC = editNPC;
window.removeNPC = removeNPC;

console.log('Cutscene Creator JS loaded');