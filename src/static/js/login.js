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

// Toast notifications
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
    
    setTimeout(() => {
        toast.classList.add('opacity-0', 'translate-y-2');
        setTimeout(() => toast.remove(), 300);
    }, 4500);
}

// On Page Load: Check URL parameters
window.addEventListener('DOMContentLoaded', () => {
    const params = new URLSearchParams(window.location.search);
    if (params.get('registered') === 'true') {
        showToast('¡Cuenta creada correctamente! Por favor inicia sesión.', 'success');
        const emailParam = params.get('email');
        if (emailParam) {
            const emailField = document.getElementById('email');
            if (emailField) {
                emailField.value = decodeURIComponent(emailParam);
                const passwordField = document.getElementById('password');
                if (passwordField) passwordField.focus();
            }
        }
    }
});

// Form Submit
const form = document.getElementById('login-form');
const submitBtn = document.getElementById('submit-btn');
const spinner = document.getElementById('spinner');

if (form && submitBtn && spinner) {
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const email = document.getElementById('email').value.trim();
        const password = document.getElementById('password').value;

        submitBtn.disabled = true;
        submitBtn.classList.add('opacity-85', 'cursor-not-allowed');
        spinner.classList.remove('hidden');

        try {
            const apiHost = window.location.origin;
            const response = await fetch(`${apiHost}/usuarios/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    correo: email,
                    contraseña: password
                })
            });

            const data = await response.json();

            if (response.ok && !data.error) {
                showToast('¡Sesión iniciada! Redirigiendo...', 'success');
                
                // Save user details to localStorage
                localStorage.setItem('currentUser', JSON.stringify(data.usuario));
                
                setTimeout(() => {
                    // Redirect to the map or dashboard page
                    window.location.href = 'puntos-mapa.html';
                }, 1500);
            } else {
                const errorMsg = data.error || 'Credenciales inválidas.';
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

// Interactive visual focus states
const inputs = document.querySelectorAll('.form-input');
inputs.forEach(input => {
    input.addEventListener('focus', () => {
        input.parentElement.classList.add('text-eco');
    });
    input.addEventListener('blur', () => {
        input.parentElement.classList.remove('text-eco');
    });
});
