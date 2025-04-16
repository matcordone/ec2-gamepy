#!/bin/bash
# Actualizar paquetes e instalar Apache y Python
yum update -y
yum install -y httpd python3

# Iniciar y habilitar Apache
systemctl start httpd
systemctl enable httpd

# Crear directorio CGI y establecer permisos
mkdir -p /var/www/cgi-bin
chmod 755 /var/www/cgi-bin

# Crear el script de juego Python con el auto 3D
cat > /var/www/cgi-bin/game.py << 'EOF'
#!/usr/bin/env python3
print("Content-type: text/html\n\n")
print("""
<!DOCTYPE html>
<html>
<head>
    <title>Juego de Auto 3D</title>
    <style>
        body { margin: 0; overflow: hidden; }
        canvas { display: block; }
        #info {
            position: absolute;
            top: 10px;
            width: 100%;
            text-align: center;
            color: white;
            font-family: Arial, sans-serif;
            font-size: 18px;
            text-shadow: 1px 1px 1px rgba(0,0,0,0.8);
            pointer-events: none;
        }
        #controls {
            position: absolute;
            bottom: 20px;
            width: 100%;
            text-align: center;
            color: white;
        }
    </style>
</head>
<body>
    <div id="info">Usa las teclas de flecha o WASD para mover el auto</div>
    <div id="controls">
        Controles: ⬆️ Acelerar, ⬇️ Frenar, ⬅️ Izquierda, ➡️ Derecha
    </div>
    
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script>
        // Configuración básica
        const scene = new THREE.Scene();
        scene.background = new THREE.Color(0x87ceeb); // Color cielo
        
        const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
        camera.position.set(0, 5, 10);
        camera.lookAt(0, 0, 0);
        
        const renderer = new THREE.WebGLRenderer({antialias: true});
        renderer.setSize(window.innerWidth, window.innerHeight);
        document.body.appendChild(renderer.domElement);
        
        // Luces
        const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
        scene.add(ambientLight);
        
        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        directionalLight.position.set(10, 20, 0);
        scene.add(directionalLight);
        
        // Crear el suelo
        const groundGeometry = new THREE.PlaneGeometry(100, 100);
        const groundMaterial = new THREE.MeshStandardMaterial({
            color: 0x1e8449,
            side: THREE.DoubleSide
        });
        const ground = new THREE.Mesh(groundGeometry, groundMaterial);
        ground.rotation.x = -Math.PI / 2;
        scene.add(ground);
        
        // Crear carretera
        const roadGeometry = new THREE.PlaneGeometry(10, 100);
        const roadMaterial = new THREE.MeshStandardMaterial({
            color: 0x333333,
            side: THREE.DoubleSide
        });
        const road = new THREE.Mesh(roadGeometry, roadMaterial);
        road.rotation.x = -Math.PI / 2;
        road.position.y = 0.01; // Ligeramente por encima del suelo para evitar z-fighting
        scene.add(road);
        
        // Marcas en la carretera
        for (let i = -50; i < 50; i += 5) {
            const markGeometry = new THREE.PlaneGeometry(0.5, 2);
            const markMaterial = new THREE.MeshStandardMaterial({
                color: 0xffffff,
                side: THREE.DoubleSide
            });
            const mark = new THREE.Mesh(markGeometry, markMaterial);
            mark.rotation.x = -Math.PI / 2;
            mark.position.set(0, 0.02, i);
            scene.add(mark);
        }
        
        // Crear auto simple
        const carGroup = new THREE.Group();
        
        // Cuerpo principal del auto
        const carBodyGeometry = new THREE.BoxGeometry(2, 0.6, 4);
        const carBodyMaterial = new THREE.MeshStandardMaterial({color: 0xff0000});
        const carBody = new THREE.Mesh(carBodyGeometry, carBodyMaterial);
        carBody.position.y = 0.5;
        carGroup.add(carBody);
        
        // Cabina
        const cabinGeometry = new THREE.BoxGeometry(1.5, 0.5, 2);
        const cabinMaterial = new THREE.MeshStandardMaterial({color: 0x2980b9});
        const cabin = new THREE.Mesh(cabinGeometry, cabinMaterial);
        cabin.position.set(0, 1.1, 0);
        carGroup.add(cabin);
        
        // Ruedas
        function createWheel(x, z) {
            const wheelGeometry = new THREE.CylinderGeometry(0.4, 0.4, 0.3, 16);
            const wheelMaterial = new THREE.MeshStandardMaterial({color: 0x333333});
            const wheel = new THREE.Mesh(wheelGeometry, wheelMaterial);
            wheel.rotation.z = Math.PI / 2;
            wheel.position.set(x, 0.4, z);
            return wheel;
        }
        
        carGroup.add(createWheel(-1, -1.2));
        carGroup.add(createWheel(1, -1.2));
        carGroup.add(createWheel(-1, 1.2));
        carGroup.add(createWheel(1, 1.2));
        
        // Faros delanteros
        function createHeadlight(x) {
            const lightGeometry = new THREE.SphereGeometry(0.2, 8, 8);
            const lightMaterial = new THREE.MeshStandardMaterial({color: 0xffff00, emissive: 0xffff00});
            const light = new THREE.Mesh(lightGeometry, lightMaterial);
            light.position.set(x, 0.5, 2);
            return light;
        }
        
        carGroup.add(createHeadlight(-0.7));
        carGroup.add(createHeadlight(0.7));
        
        scene.add(carGroup);
        
        // Variables para el movimiento
        const car = {
            position: {x: 0, y: 0.7, z: 0},
            speed: 0,
            acceleration: 0.01,
            deceleration: 0.007,
            maxSpeed: 0.3,
            steering: 0.05,
            rotation: 0,
            moveForward: false,
            moveBackward: false,
            moveLeft: false,
            moveRight: false
        };
        
        // Controles de teclado
        document.addEventListener('keydown', function(event) {
            switch(event.key) {
                case 'ArrowUp':
                case 'w':
                case 'W':
                    car.moveForward = true;
                    break;
                    
                case 'ArrowDown':
                case 's':
                case 'S':
                    car.moveBackward = true;
                    break;
                    
                case 'ArrowLeft':
                case 'a':
                case 'A':
                    car.moveLeft = true;
                    break;
                    
                case 'ArrowRight':
                case 'd':
                case 'D':
                    car.moveRight = true;
                    break;
            }
        });
        
        document.addEventListener('keyup', function(event) {
            switch(event.key) {
                case 'ArrowUp':
                case 'w':
                case 'W':
                    car.moveForward = false;
                    break;
                    
                case 'ArrowDown':
                case 's':
                case 'S':
                    car.moveBackward = false;
                    break;
                    
                case 'ArrowLeft':
                case 'a':
                case 'A':
                    car.moveLeft = false;
                    break;
                    
                case 'ArrowRight':
                case 'd':
                case 'D':
                    car.moveRight = false;
                    break;
            }
        });
        
        // Añadir árboles aleatorios
        function createTree(x, z) {
            const treeGroup = new THREE.Group();
            
            // Tronco
            const trunkGeometry = new THREE.CylinderGeometry(0.2, 0.3, 2, 8);
            const trunkMaterial = new THREE.MeshStandardMaterial({color: 0x8B4513});
            const trunk = new THREE.Mesh(trunkGeometry, trunkMaterial);
            trunk.position.y = 1;
            treeGroup.add(trunk);
            
            // Copa
            const topGeometry = new THREE.ConeGeometry(1, 2, 8);
            const topMaterial = new THREE.MeshStandardMaterial({color: 0x228B22});
            const top = new THREE.Mesh(topGeometry, topMaterial);
            top.position.y = 2.5;
            treeGroup.add(top);
            
            treeGroup.position.set(x, 0, z);
            scene.add(treeGroup);
        }
        
        // Crear árboles aleatorios
        for (let i = 0; i < 50; i++) {
            const x = Math.random() * 80 - 40;
            const z = Math.random() * 80 - 40;
            // Evitar colocar árboles en la carretera
            if (Math.abs(x) > 5) {
                createTree(x, z);
            }
        }
        
        // Función de animación
        function animate() {
            requestAnimationFrame(animate);
            
            // Actualizar velocidad del auto
            if (car.moveForward) {
                car.speed = Math.min(car.speed + car.acceleration, car.maxSpeed);
            } else if (car.moveBackward) {
                car.speed = Math.max(car.speed - car.acceleration, -car.maxSpeed/2);
            } else {
                if (car.speed > 0) {
                    car.speed = Math.max(car.speed - car.deceleration, 0);
                } else if (car.speed < 0) {
                    car.speed = Math.min(car.speed + car.deceleration, 0);
                }
            }
            
            // Girar solo si el auto está en movimiento
            if (Math.abs(car.speed) > 0.01) {
                if (car.moveLeft) {
                    car.rotation += car.steering * Math.sign(car.speed);
                }
                if (car.moveRight) {
                    car.rotation -= car.steering * Math.sign(car.speed);
                }
            }
            
            // Calcular nueva posición
            car.position.x += Math.sin(car.rotation) * car.speed;
            car.position.z += Math.cos(car.rotation) * car.speed;
            
            // Limitar área de movimiento
            car.position.x = Math.max(Math.min(car.position.x, 45), -45);
            car.position.z = Math.max(Math.min(car.position.z, 45), -45);
            
            // Actualizar posición y rotación del auto
            carGroup.position.set(car.position.x, car.position.y, car.position.z);
            carGroup.rotation.y = car.rotation;
            
            // Actualizar cámara para seguir al auto
            camera.position.x = car.position.x - Math.sin(car.rotation) * 10;
            camera.position.z = car.position.z - Math.cos(car.rotation) * 10;
            camera.position.y = car.position.y + 5;
            camera.lookAt(car.position.x, car.position.y, car.position.z);
            
            renderer.render(scene, camera);
        }
        
        // Manejar cambio de tamaño de ventana
        window.addEventListener('resize', function() {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });
        
        animate();
    </script>
</body>
</html>
""")
EOF

# Hacer el script ejecutable
chmod 755 /var/www/cgi-bin/game.py

# Configurar Apache para CGI
cat > /etc/httpd/conf.d/cgi.conf << 'EOF'
ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"
<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options +ExecCGI
    Require all granted
    AddHandler cgi-script .py
</Directory>
EOF

# Crear una página de redirección en la raíz
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Redireccionando al juego</title>
    <meta http-equiv="refresh" content="0;url=/cgi-bin/game.py">
</head>
<body>
    <p>Redireccionando al juego...</p>
    <p>Si no eres redireccionado automáticamente, <a href="/cgi-bin/game.py">haz clic aquí</a>.</p>
</body>
</html>
EOF
# Reiniciar Apache para aplicar cambios
systemctl restart httpd