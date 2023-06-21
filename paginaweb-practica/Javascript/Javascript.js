function chequeo() {
    var usuario = {
        nombre: "Pepe",
        apellido: "Pepito",
        edad: 17,
        aniosExperiencia: 0,
        aniosEstudio: 0,
        localidad: "Catamarca",
        sigueEstudiando: false,
        colores: ["negro", "Amarillo", "verde",],
    }
    
    
    if (usuario.edad >= 18){
        alert("mayor de edad");
    }
    else {
        alert("Menor de edad");
    }
    
    // Si es de Buenos aires
    if (usuario.localidad == "Buenos aires"){
        alert("Vive cerca");
    } else {
        alert("Vive lejos");
    }
    
    // si sigue estudiando
    if (usuario.sigueEstudiando == true){
        alert("Estudiando");
    } else {
        alert("No estudia");
    }
    
    // si tiene 2 años de estudios o 2 añois de experiencia
    
    if (usuario.aniosEstudio >= 2 || usuario.aniosExperiencia >= 2){
        alert("Apto para un posible trabajo")
    } else {
        alert("Debe estudiar o trabajar mas")
    }
    
}

function obtenerSumatoria() {
    var resultado = 0;
    for (i = 0; i <= 10; i++ ) {
        //console.log ("mi valor es " + i);
        resultado = resultado + i;
        
    }
    console.log ("Mi resultado es" + resultado);
}


obtenerSumatoria();

