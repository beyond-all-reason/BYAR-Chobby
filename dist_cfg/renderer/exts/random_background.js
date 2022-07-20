'use strict';

const images = [];
for (let i = 1; i <= 18; ++i) {
    images.push(`./images/backgrounds/${i}.avif`);
}
var imageName = images[Math.floor(Math.random() * images.length)];
//console.log("ImageName:" +imageName);          
document.getElementById("main-content").style.backgroundImage = "url("+imageName+")"; 