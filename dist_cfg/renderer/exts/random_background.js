'use strict';

var images = [  './images/backgrounds/1.png',
                './images/backgrounds/2.png',
                './images/backgrounds/3.png',
            ];        

var imageName = images[Math.floor(Math.random() * images.length)];
//console.log("ImageName:" +imageName);          
document.getElementById("main-content").style.backgroundImage = "url("+imageName+")"; 