// Cutscene Creator JavaScript - FIXED VERSION
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

// Global resource name
let resourceName = null;

// Get resource name helper - must be defined early
function GetParentResourceName() {
    // Try window.location.host first (FiveM sets this)
    if (window.location.host && window.location.host !== '') {
        return window.location.host;
    }
    
    // Fallback to extracting from pathname
    const pathMatch = window.location.pathname.match(/^\/([^\/]+)\//);
    if (pathMatch && pathMatch[1]) {
        return pathMatch[1];
    }
    
    // Last resort fallback
    return 'fivem-story-rp-core';
}

// Debug: Log window location info on load
console.log('=== Cutscene Creator Loaded ===');
console.log('Window location info:');
console.log('  host:', window.location.host);
console.log('  hostname:', window.location.hostname);
console.log('  pathname:', window.location.pathname);
console.log('  href:', window.location.href);
console.log('  protocol:', window.location.protocol);
console.log('Detected resource name:', GetParentResourceName());
console.log('================================');

// Message listener
window.addEventListener('message', (event) => {
    const data = event.data;
    
    try {
        if (data.action === 'openCreator') {
            console.log('Opening creator', data);
            
            // Store resource name from the first message
            if (!resourceName && data.resourceName) {
                resourceName = data.resourceName;
                console.log('Resource name set to:', resourceName);
            }
            
            // Store data
            if (data.data) {
                if (data.data.cutscene) {
                    cutsceneData = data.data.cutscene;
                }
                if (data.data.config) {
                    config = data.data.config;
                }
            }
            
            // Show container
            const container = document.getElementById('creator-container');
            if (container) {
                container.classList.remove('hidden');
            }
            
            // Initialize UI components first
            if (!isInitialized) {
                initializeUI();
                isInitialized = true;
            }
            
            // Then initialize dynamic content
            initializeComponents();
            
            // Finally update with data
            updateUI();
            
        } else if (data.action === 'closeCreator') {
            console.log('Closing creator');
            const container = document.getElementById('creator-container');
            if (container) {
                container.classList.add('hidden');
            }
            selectedNPC = null;
            hideNPCEditor();
            
        } else if (data.action === 'updateCutscene') {
            console.log('Updating cutscene', data);
            if (data.data) {
                cutsceneData = data.data;
                updateUI();
            }
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
    console.log('Initializing components', config);
    
    // Components list
    const componentsList = document.getElementById('componentsList');
    if (componentsList && config.components) {
        componentsList.innerHTML = '';
        
        for (const [id, name] of Object.entries(config.components)) {
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
    if (propsList && config.props) {
        propsList.innerHTML = '';
        
        for (const [id, name] of Object.entries(config.props)) {
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
    if (animSelect && config.animations) {
        animSelect.innerHTML = '<option value="">Nincs</option>';
        
        if (Array.isArray(config.animations)) {
            config.animations.forEach(anim => {
                const option = document.createElement('option');
                option.value = anim;
                option.textContent = anim;
                animSelect.appendChild(option);
            });
        }
    }
    
    console.log('Components initialized');
}

function updateUI() {
    console.log('Updating UI with data:', cutsceneData);
    
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
    
    if (!cutsceneData.timeline || !Array.isArray(cutsceneData.timeline)) {
        timeline.innerHTML = '<p class="info-text">Még nincs keyframe</p>';
        return;
    }
    
    cutsceneData.timeline.forEach((keyframe, index) => {
        const div = document.createElement('div');
        div.className = 'timeline-keyframe';
        
        if (keyframe && keyframe.camera) {
            div.innerHTML = `
                <strong>Keyframe ${index + 1}</strong><br>
                Idő: ${keyframe.time || 0}ms<br>
                Kamera: (${(keyframe.camera.x || 0).toFixed(2)}, ${(keyframe.camera.y || 0).toFixed(2)}, ${(keyframe.camera.z || 0).toFixed(2)})
            `;
        } else {
            div.innerHTML = `<strong>Keyframe ${index + 1}</strong><br>Érvénytelen adat`;
        }
        
        timeline.appendChild(div);
    });
}

function updateNPCListUI() {
    const npcList = document.getElementById('npcList');
    if (!npcList) return;
    
    npcList.innerHTML = '';
    
    if (!cutsceneData.npcs || !Array.isArray(cutsceneData.npcs) || cutsceneData.npcs.length === 0) {
        npcList.innerHTML = '<p class="info-text">Még nincs NPC</p>';
        return;
    }
    
    cutsceneData.npcs.forEach((npc, index) => {
        const div = document.createElement('div');
        div.className = 'npc-item';
        div.innerHTML = `
            <span>NPC ${index + 1} - ${npc.model || 'Unknown'}</span>
            <div class="npc-item-actions">
                <button class="btn btn-primary btn-small" onclick="window.editNPC(${index})">Szerkeszt</button>
                <button class="btn btn-danger btn-small" onclick="window.removeNPC(${index})">Törlés</button>
            </div>
        `;
        npcList.appendChild(div);
    });
}

function addKeyframe() {
    console.log('Adding keyframe');
    
    sendNUI('addKeyframe', {
        time: (cutsceneData.timeline ? cutsceneData.timeline.length : 0) * 1000
    }).then(data => {
        if (data && data.success && data.keyframe) {
            if (!cutsceneData.timeline) {
                cutsceneData.timeline = [];
            }
            cutsceneData.timeline.push(data.keyframe);
            updateTimelineUI();
            console.log('Keyframe added successfully');
        } else {
            console.error('Failed to add keyframe:', data);
            alert('Hiba a keyframe hozzáadásakor!');
        }
    }).catch(err => {
        console.error('Add keyframe error:', err);
        alert('Hiba történt a keyframe hozzáadásakor!');
    });
}

function addNPC() {
    console.log('Adding NPC');
    
    const model = prompt("Model név (pl: mp_m_freemode_01):", "mp_m_freemode_01");
    if (!model || model.trim() === '') {
        console.log('NPC add cancelled - no model');
        return;
    }
    
    // Show loading state
    const addNPCBtn = document.getElementById('addNPCBtn');
    const originalText = addNPCBtn ? addNPCBtn.textContent : '';
    if (addNPCBtn) {
        addNPCBtn.disabled = true;
        addNPCBtn.textContent = 'Hozzáadás...';
    }
    
    sendNUI('addNPC', { model: model.trim() })
        .then(data => {
            console.log('Add NPC response:', data);
            
            if (data && data.success && data.npc) {
                if (!cutsceneData.npcs) {
                    cutsceneData.npcs = [];
                }
                cutsceneData.npcs.push(data.npc);
                updateNPCListUI();
                console.log('NPC added successfully:', data.npcId);
            } else {
                console.error('Failed to add NPC:', data);
                alert('Hiba: ' + (data && data.error ? data.error : 'Ismeretlen hiba'));
            }
        })
        .catch(err => {
            console.error('Add NPC error:', err);
            alert('Hiba történt az NPC hozzáadásakor: ' + err.message);
        })
        .finally(() => {
            // Restore button state
            if (addNPCBtn) {
                addNPCBtn.disabled = false;
                addNPCBtn.textContent = originalText;
            }
        });
}

function editNPC(npcId) {
    console.log('Editing NPC:', npcId);
    
    if (!cutsceneData.npcs || !cutsceneData.npcs[npcId]) {
        console.error('NPC not found:', npcId);
        alert('NPC nem található!');
        return;
    }
    
    selectedNPC = npcId;
    const npc = cutsceneData.npcs[npcId];
    
    // Show editor
    showNPCEditor();
    
    // Set model
    const modelInput = document.getElementById('npcModel');
    if (modelInput) {
        modelInput.value = npc.model || '';
    }
    
    // Reset all inputs first
    resetClothingInputs();
    
    // Load clothing
    if (npc.clothing) {
        if (npc.clothing.components) {
            for (const [id, data] of Object.entries(npc.clothing.components)) {
                const drawable = document.querySelector(`.component-drawable[data-id="${id}"]`);
                const texture = document.querySelector(`.component-texture[data-id="${id}"]`);
                if (drawable) drawable.value = data.drawable || 0;
                if (texture) texture.value = data.texture || 0;
            }
        }
        
        if (npc.clothing.props) {
            for (const [id, data] of Object.entries(npc.clothing.props)) {
                const drawable = document.querySelector(`.prop-drawable[data-id="${id}"]`);
                const texture = document.querySelector(`.prop-texture[data-id="${id}"]`);
                if (drawable) drawable.value = data.drawable || -1;
                if (texture) texture.value = data.texture || 0;
            }
        }
    }
    
    console.log('NPC editor shown for NPC', npcId);
}

function showNPCEditor() {
    const editor = document.getElementById('npcEditor');
    if (editor) {
        editor.classList.remove('hidden');
        // Scroll to editor
        editor.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
}

function hideNPCEditor() {
    const editor = document.getElementById('npcEditor');
    if (editor) {
        editor.classList.add('hidden');
    }
}

function resetClothingInputs() {
    // Reset components
    document.querySelectorAll('.component-drawable').forEach(input => {
        input.value = 0;
    });
    document.querySelectorAll('.component-texture').forEach(input => {
        input.value = 0;
    });
    
    // Reset props
    document.querySelectorAll('.prop-drawable').forEach(input => {
        input.value = -1;
    });
    document.querySelectorAll('.prop-texture').forEach(input => {
        input.value = 0;
    });
}

function removeNPC(npcId) {
    console.log('Removing NPC:', npcId);
    
    if (!confirm('Biztosan törlöd ezt az NPC-t?')) {
        return;
    }
    
    sendNUI('removeNPC', { npcId: npcId }).then(data => {
        if (data && data.success) {
            if (cutsceneData.npcs && cutsceneData.npcs[npcId]) {
                cutsceneData.npcs.splice(npcId, 1);
                updateNPCListUI();
                
                // Hide editor if this NPC was being edited
                if (selectedNPC === npcId) {
                    cancelNPCEdit();
                }
                
                console.log('NPC removed successfully');
            }
        } else {
            console.error('Failed to remove NPC:', data);
            alert('Hiba történt az NPC törlésekor!');
        }
    }).catch(err => {
        console.error('Remove NPC error:', err);
        alert('Hiba történt az NPC törlésekor!');
    });
}

function saveNPCClothing() {
    console.log('Saving NPC clothing for NPC:', selectedNPC);
    
    if (selectedNPC === null || selectedNPC === undefined) {
        console.error('No NPC selected');
        alert('Nincs kiválasztott NPC!');
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
        const drawable = parseInt(input.value);
        const textureInput = document.querySelector(`.prop-texture[data-id="${id}"]`);
        const texture = textureInput ? parseInt(textureInput.value) || 0 : 0;
        
        // Only include props that are not -1 (disabled)
        if (!isNaN(drawable)) {
            clothing.props[id] = { drawable, texture };
        }
    });
    
    console.log('Collected clothing data:', clothing);
    
    sendNUI('updateNPCClothing', {
        npcId: selectedNPC,
        clothing: clothing
    }).then(data => {
        if (data && data.success) {
            // Update local data
            if (cutsceneData.npcs && cutsceneData.npcs[selectedNPC]) {
                cutsceneData.npcs[selectedNPC].clothing = clothing;
            }
            
            alert('NPC ruházat mentve!');
            cancelNPCEdit();
            console.log('NPC clothing saved successfully');
        } else {
            console.error('Failed to save NPC clothing:', data);
            alert('Hiba történt a mentés során!');
        }
    }).catch(err => {
        console.error('Save NPC error:', err);
        alert('Hiba történt a mentés során!');
    });
}

function cancelNPCEdit() {
    hideNPCEditor();
    selectedNPC = null;
    console.log('NPC edit cancelled');
}

function previewCutscene() {
    console.log('Previewing cutscene');
    
    const nameInput = document.getElementById('cutsceneName');
    const durationInput = document.getElementById('cutsceneDuration');
    
    if (nameInput) cutsceneData.name = nameInput.value;
    if (durationInput) cutsceneData.duration = parseInt(durationInput.value) || 30000;
    
    sendNUI('previewCutscene', cutsceneData)
        .then(() => {
            console.log('Preview started');
        })
        .catch(err => console.error('Preview error:', err));
}

function saveCutscene() {
    console.log('Saving cutscene');
    
    const nameInput = document.getElementById('cutsceneName');
    const durationInput = document.getElementById('cutsceneDuration');
    
    const name = nameInput ? nameInput.value : '';
    const duration = durationInput ? parseInt(durationInput.value) : 30000;
    
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
        if (data && data.success) {
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
    if (!name || name.trim() === '') {
        return;
    }
    
    sendNUI('loadCutscene', { name: name.trim() })
        .then(() => {
            console.log('Load request sent');
        })
        .catch(err => console.error('Load error:', err));
}

function sendNUI(action, data) {
    console.log('Sending NUI:', action, data);
    
    // Use stored resource name or fallback
    const resName = resourceName || GetParentResourceName();
    const url = `https://${resName}/${action}`;
    
    console.log('NUI URL:', url);
    
    return fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data || {})
    })
    .then(response => {
        console.log('NUI response status:', action, response.status, response.ok);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
    })
    .then(responseData => {
        console.log('NUI response data:', action, responseData);
        return responseData;
    })
    .catch(error => {
        console.error('NUI request error:', action, error);
        console.error('Using resource name:', resName);
        throw error;
    });
}

// Make functions globally available
window.editNPC = editNPC;
window.removeNPC = removeNPC;

console.log('Cutscene Creator JS loaded and initialized');