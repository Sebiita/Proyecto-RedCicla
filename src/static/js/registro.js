// Password Visibility Toggle
function togglePasswordVisibility(fieldId, button) {
    const input = document.getElementById(fieldId);
    const eyeOpen = button.querySelector('.eye-open');
    const eyeClosed = button.querySelector('.eye-closed');
    
    if (input.type === 'password') {
        input.type = 'text';
        eyeOpen.classList.add('hidden');
        eyeClosed.classList.remove('hidden');
    } else {
        input.type = 'password';
        eyeOpen.classList.remove('hidden');
        eyeClosed.classList.add('hidden');
    }
}

// Live Password Strength Check
const passwordInput = document.getElementById('contraseña');
const strengthBarFill = document.querySelector('.strength-bar-fill');
const strengthText = document.getElementById('password-strength-text');

if (passwordInput && strengthBarFill && strengthText) {
    passwordInput.addEventListener('input', () => {
        const val = passwordInput.value;
        let score = 0;
        
        if (val.length >= 6) score += 1;
        if (val.length >= 10) score += 1;
        if (/[A-Z]/.test(val)) score += 1;
        if (/[0-9]/.test(val)) score += 1;
        if (/[^A-Za-z0-9]/.test(val)) score += 1;

        // Reset
        strengthBarFill.className = 'strength-bar-fill h-full rounded transition-all duration-300';
        
        if (val.length === 0) {
            strengthBarFill.style.width = '0%';
            strengthText.innerText = 'Muy corta';
            strengthText.className = 'text-[10px] font-semibold text-gray-400 uppercase tracking-wider';
        } else if (val.length < 6) {
            strengthBarFill.style.width = '20%';
            strengthBarFill.classList.add('bg-red-500');
            strengthText.innerText = 'Muy corta';
            strengthText.className = 'text-[10px] font-semibold text-red-500 uppercase tracking-wider';
        } else if (score <= 2) {
            strengthBarFill.style.width = '50%';
            strengthBarFill.classList.add('bg-yellow-500');
            strengthText.innerText = 'Media';
            strengthText.className = 'text-[10px] font-semibold text-yellow-600 uppercase tracking-wider';
        } else {
            strengthBarFill.style.width = '100%';
            strengthBarFill.classList.add('bg-green-500');
            strengthText.innerText = 'Fuerte';
            strengthText.className = 'text-[10px] font-semibold text-green-600 tracking-wider';
        }
    });
}

// Elegant Toast notification system
function showToast(message, type = 'success') {
    const container = document.getElementById('toast-container');
    if (!container) return;
    
    const toast = document.createElement('div');
    const isSuccess = type === 'success';
    const bgClass = isSuccess ? 'bg-white border-green-200' : 'bg-white border-red-200';
    const iconColor = isSuccess ? 'text-green-500' : 'text-red-500';
    const iconSvg = isSuccess 
        ? `<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>`
        : `<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>`;

    toast.className = `flex items-center gap-3 p-4 rounded-2xl border shadow-xl ${bgClass} opacity-0 translate-x-4 animate-slide-in-right transition-all duration-300`;
    toast.innerHTML = `
        <div class="${iconColor}">${iconSvg}</div>
        <div class="flex-1 text-sm font-medium text-gray-700">${message}</div>
        <button class="text-gray-400 hover:text-gray-600" onclick="this.parentElement.remove()">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
        </button>
    `;
    
    container.appendChild(toast);
    
    // Auto remove
    setTimeout(() => {
        toast.classList.add('opacity-0', 'translate-y-2');
        setTimeout(() => toast.remove(), 300);
    }, 4500);
}

// Form Submit handler via API
const form = document.getElementById('register-form');
const submitBtn = document.getElementById('submit-btn');
const spinner = document.getElementById('spinner');

if (form && submitBtn && spinner) {
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const nombre = document.getElementById('nombre').value.trim();
        const apellido = document.getElementById('apellido').value.trim();
        const correo = document.getElementById('correo').value.trim();
        const rol = document.getElementById('rol').value;
        const contraseña = document.getElementById('contraseña').value;
        const confirmContraseña = document.getElementById('confirmar-contraseña').value;

        // Password confirmation validation
        if (contraseña !== confirmContraseña) {
            showToast('Las contraseñas no coinciden', 'error');
            const confirmInput = document.getElementById('confirmar-contraseña');
            confirmInput.classList.add('border-red-400', 'animate-shake');
            confirmInput.focus();
            setTimeout(() => confirmInput.classList.remove('animate-shake'), 400);
            return;
        }

        // Disable button and show spinner
        submitBtn.disabled = true;
        submitBtn.classList.add('opacity-85', 'cursor-not-allowed');
        spinner.classList.remove('hidden');

        try {
            // Perform HTTP Request to API (FastAPI backend)
            const apiHost = window.location.origin;
            const response = await fetch(`${apiHost}/usuarios/registrar`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    nombre: nombre,
                    apellido: apellido,
                    correo: correo,
                    rol: rol,
                    contraseña: contraseña,
                    estado: 'Activo'
                })
            });

            const data = await response.json();

            if (response.ok && !data.error) {
                showToast('¡Registro exitoso! Redirigiendo al inicio de sesión...', 'success');
                
                // Soft fade out card and redirect
                setTimeout(() => {
                    const card = document.querySelector('.bg-white\\/90');
                    if (card) {
                        card.style.transition = 'all 0.5s ease';
                        card.style.opacity = '0';
                        card.style.transform = 'translateY(-20px)';
                    }
                    
                    setTimeout(() => {
                        // Send custom param to login page to prefill email and show message
                        window.location.href = `login.html?registered=true&email=${encodeURIComponent(correo)}`;
                    }, 500);
                }, 2000);
            } else {
                const errorMsg = data.error || 'Ocurrió un error al registrar la cuenta.';
                showToast(errorMsg, 'error');
                submitBtn.disabled = false;
                submitBtn.classList.remove('opacity-85', 'cursor-not-allowed');
                spinner.classList.add('hidden');
            }
        } catch (err) {
            console.error(err);
            showToast('Error de conexión con el servidor. Inténtalo más tarde.', 'error');
            submitBtn.disabled = false;
            submitBtn.classList.remove('opacity-85', 'cursor-not-allowed');
            spinner.classList.add('hidden');
        }
    });
}

// Visual highlight focus effects
const inputs = document.querySelectorAll('.form-input');
inputs.forEach(input => {
    input.addEventListener('focus', () => {
        input.parentElement.classList.add('text-eco');
    });
    input.addEventListener('blur', () => {
        input.parentElement.classList.remove('text-eco');
        if (input.id === 'confirmar-contraseña') {
            input.classList.remove('border-red-400');
        }
    });
});
