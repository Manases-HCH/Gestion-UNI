<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <div class="container-fluid">
        <a class="navbar-brand" href="#">
            <img src="img/logo_ugic.png" alt="Logo UGIC"> UGIC Portal
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent"
                aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarSupportedContent">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="carrerasPregradoDropdown" role="button"
                       data-bs-toggle="dropdown" aria-expanded="false">
                        Carreras Pregrado
                    </a>
                    <ul class="dropdown-menu" aria-labelledby="carrerasPregradoDropdown">
                        <li><a class="dropdown-item" href="Carreras/Ingenieria de Sistemas.jsp">Ingeniería de Sistemas</a></li>
                        <li><a class="dropdown-item" href="Carreras/Administración de Empresas.jsp">Administración de Empresas</a></li>
                        <li><a class="dropdown-item" href="Carreras/Derecho.jsp">Derecho</a></li>
                        <li><a class="dropdown-item" href="Carreras/Contabilidad.jsp">Contabilidad</a></li>
                        <li><a class="dropdown-item" href="Carreras/Ingeniería Industrial.jsp">Ingeniería Industrial</a></li>
                        <li><a class="dropdown-item" href="Carreras/Ingeniería Civil.jsp">Ingeniería Civil</a></li>
                        <li><a class="dropdown-item" href="Carreras/Psicología.jsp">Psicología</a></li>
                        <li><a class="dropdown-item" href="Carreras/Educación Inicial.jsp">Educación Inicial</a></li>
                        <li><a class="dropdown-item" href="Carreras/Ciencias de la Comunicación.jsp">Ciencias de la Comunicación</a></li>
                        <li><a class="dropdown-item" href="Carreras/Arquitectura.jsp">Arquitectura</a></li>
                    </ul>
                </li>
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="carrerasDistanciaDropdown" role="button"
                       data-bs-toggle="dropdown" aria-expanded="false">
                        Carreras a Distancia
                    </a>
                    <ul class="dropdown-menu" aria-labelledby="carrerasDistanciaDropdown">
                        <li><a class="dropdown-item" href="#">Administración de Empresas (Virtual)</a></li>
                        <li><a class="dropdown-item" href="#">Marketing Digital (Virtual)</a></li>
                    </ul>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="#">Posgrado</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="#">Nosotros</a>
                </li>
            </ul>
            <form class="d-flex">
                <input class="form-control me-2" type="search" placeholder="Buscar" aria-label="Buscar">
                <button class="btn btn-outline-success" type="submit">Buscar</button>
            </form>
            <ul class="navbar-nav">
                <li class="nav-item">
                    <a class="nav-link" href="#">Postular a UGIC</a>
                </li>
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" id="usuarioDropdown" role="button"
                       data-bs-toggle="dropdown" aria-expanded="false">
                        <i class="fas fa-user"></i> Iniciar Sesión
                    </a>
                    <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="usuarioDropdown">
                        <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#alumnoModal">Alumno</a></li>
                        <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#profesorModal">Profesor</a></li>
                        <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#apoderadoModal">Apoderado</a></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="#" data-bs-toggle="modal" data-bs-target="#adminModal">Administrador</a></li>
                        <li><hr class="dropdown-divider"></li>                     
                    </ul>
                </li>
            </ul>
        </div>
    </div>
</nav>
<div class="modal fade" id="alumnoModal" tabindex="-1" aria-labelledby="alumnoModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header modal-header-primary bg-primary text-white">
                <h5 class="modal-title" id="alumnoModalLabel"><i class="fas fa-graduation-cap me-2"></i> Iniciar Sesión Alumno</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form action="loginServlet" method="post" onsubmit="hashPasswordBeforeSubmit(this)">
                    <input type="hidden" name="userType" value="alumnos">
                    <div class="mb-3">
                        <label for="alumnoUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario</label>
                        <input type="text" class="form-control" id="alumnoUsernameInput" name="username" placeholder="Ingrese su usuario" required>
                    </div>
                    <div class="mb-3">
                        <label for="alumnoPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña</label>
                        <input type="password" class="form-control" id="alumnoPasswordInput" name="secret" placeholder="Ingrese su contraseña" required>
                    </div>
                    <div class="form-check mb-3">
                        <input type="checkbox" class="form-check-input" id="rememberAlumno">
                        <label class="form-check-label" for="rememberAlumno">Recordarme</label>
                    </div>
                    <div class="mb-3 text-center">
                        <div class="g-recaptcha" data-sitekey="6LfURxAsAAAAAEZom8v7kwyvgfscpCANPK1Wf-WD"></div>
                    </div>
                    <div class="d-grid">
                        <button type="submit" class="btn btn-primary"><i class="fas fa-sign-in-alt me-2"></i> Iniciar Sesión</button>
                    </div>
                    <div class="mt-3 text-center">
                        <a href="#">¿Olvidó su contraseña?</a> 
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal"><i class="fas fa-times me-2"></i> Cerrar</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="profesorModal" tabindex="-1" aria-labelledby="profesorModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header bg-info text-white">
                <h5 class="modal-title" id="profesorModalLabel"><i class="fas fa-chalkboard-teacher me-2"></i> Iniciar Sesión Profesor</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form action="loginServlet" method="post">
                    <input type="hidden" name="userType" value="profesores">
                    <div class="mb-3">
                        <label for="profesorUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario </label>
                        <input type="text" class="form-control" id="profesorUsernameInput" name="username" placeholder="Ingrese su usuario de profesor" required>
                    </div>
                    <div class="mb-3">
                        <label for="profesorPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña </label>
                        <input type="password" class="form-control" id="profesorPasswordInput" name="secret" placeholder="Ingrese su contraseña" required>
                    </div>
                    <div class="form-check mb-3">
                        <input type="checkbox" class="form-check-input" id="rememberProfesor">
                        <label class="form-check-label" for="rememberProfesor">Recordarme</label>
                    </div>
                    <div class="mb-3 text-center">
                        <div class="g-recaptcha" data-sitekey="6LfURxAsAAAAAEZom8v7kwyvgfscpCANPK1Wf-WD"></div>
                    </div>
                    <div class="d-grid">
                        <button type="submit" class="btn btn-info"><i class="fas fa-sign-in-alt me-2"></i> Iniciar Sesión</button>
                    </div>
                    <div class="mt-3 text-center">
                        <a href="#">¿Olvidó su contraseña?</a> 
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal"><i class="fas fa-times me-2"></i> Cerrar</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="apoderadoModal" tabindex="-1" aria-labelledby="apoderadoModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header bg-warning text-dark">
                <h5 class="modal-title" id="apoderadoModalLabel"><i class="fas fa-user-friends me-2"></i> Iniciar Sesión Apoderado</h5>
                <button type="button" class="btn-close btn-close-dark" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form action="loginServlet" method="post">
                    <input type="hidden" name="userType" value="apoderados">
                    <div class="mb-3">
                        <label for="apoderadoUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario</label>
                        <input type="text" class="form-control" id="apoderadoUsernameInput" name="username" placeholder="Ingrese su usuario de apoderado" required>
                    </div>
                    <div class="mb-3">
                        <label for="apoderadoPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña</label>
                        <input type="password" class="form-control" id="apoderadoPasswordInput" name="secret" placeholder="Ingrese su contraseña" required>
                    </div>
                    <div class="form-check mb-3">
                        <input type="checkbox" class="form-check-input" id="rememberApoderado">
                        <label class="form-check-label" for="rememberApoderado">Recordarme</label>
                    </div>
                    <div class="mb-3 text-center">
                        <div class="g-recaptcha" data-sitekey="6LfURxAsAAAAAEZom8v7kwyvgfscpCANPK1Wf-WD"></div>
                    </div>
                    <div class="d-grid">
                        <button type="submit" class="btn btn-warning text-dark"><i class="fas fa-sign-in-alt me-2"></i> Iniciar Sesión</button>
                    </div>
                    <div class="mt-3 text-center">
                        <a href="#">¿Olvidó su contraseña?</a> 
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal"><i class="fas fa-times me-2"></i> Cerrar</button>
            </div>
        </div>
    </div>
</div>
<div class="modal fade" id="adminModal" tabindex="-1" aria-labelledby="adminModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header bg-success text-white">
                <h5 class="modal-title" id="adminModalLabel"><i class="fas fa-user-shield me-2"></i> Iniciar Sesión Administrador</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form action="https://gestion-uni.onrender.com/loginServlet" method="post" onsubmit="return secureHashPassword(this)">
                    <input type="hidden" name="userType" value="admin">
                    <div class="mb-3">
                        <label for="adminUsernameModal" class="form-label"><i class="fas fa-user me-2"></i> Usuario </label>
                        <input type="text" class="form-control" id="adminUsernameInput" name="username" placeholder="Ingrese su usuario de administrador" required>
                    </div>
                    <div class="mb-3">
                        <label for="adminPasswordModal" class="form-label"><i class="fas fa-lock me-2"></i> Contraseña </label>
                        <input type="password" class="form-control" id="adminPasswordInput" name="secret" placeholder="Ingrese su contraseña" required>
                    </div>
                    <div class="form-check mb-3">
                        <input type="checkbox" class="form-check-input" id="rememberAdmin">
                        <label class="form-check-label" for="rememberAdmin">Recordarme</label>
                    </div>
                    <div class="mb-3 text-center">
                        <div class="g-recaptcha" data-sitekey="6LfURxAsAAAAAEZom8v7kwyvgfscpCANPK1Wf-WD"></div>
                    </div>
                    <div class="d-grid">
                        <button type="submit" class="btn btn-success"><i class="fas fa-sign-in-alt me-2"></i> Iniciar Sesión</button>
                    </div>
                    <div class="mt-3 text-center">
                        <a href="#">¿Olvidó su contraseña?</a> 
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal"><i class="fas fa-times me-2"></i> Cerrar</button>
            </div>
        </div>
    </div>
</div>
<script src="https://www.google.com/recaptcha/api.js" async defer></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/bcryptjs/2.4.3/bcrypt.min.js"></script>


<script>
async function secureHashPassword(form) {
    const input = form.querySelector("input[name='secret']");
    const plain = input.value.trim();
    if (!plain) return;

    // SHA-256 en frontend
    const encoder = new TextEncoder();
    const data = encoder.encode(plain);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);

    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const sha256 = hashArray.map(b => b.toString(16).padStart(2, "0")).join("");

    // Reemplazar la contraseña por su SHA-256
    input.value = sha256;
}
</script>
