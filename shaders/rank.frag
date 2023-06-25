uniform sampler2D tex0;
uniform float time;

const float flashTime = 1.0;
const float normalizeTime = 8.0;
const float delta = normalizeTime - flashTime;

const float flashAmount = 0.7;

void main() {
    vec4 col = texture2D(tex0, gl_TexCoord[0].st);

    float dCenter = length(gl_TexCoord[0].st - vec2(0.5, 0.5));
    dCenter = 1.0 / (5.0 * dCenter + 1.0);

    vec4 dCenterVec = vec4(dCenter);
    // cosine similarity
    float sim = dot(dCenterVec, col) / (length(dCenterVec) * length(col) + 0.01);
    vec4 flashVector = dCenterVec * sim;

    if (time < flashTime) {
        col = mix(flashVector, col, (1.0 - flashAmount) + (flashTime - time) / flashTime);
    } else if (time < normalizeTime) {
        col = mix(col, flashVector, (normalizeTime - time) / delta - (1.0 - flashAmount));
    }

    gl_FragColor = col;
}
