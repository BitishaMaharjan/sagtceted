precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

// random
float rand(vec2 n) {
  return fract(sin(dot(n, vec2(12.9898,78.233))) * 43758.5453123);
}

// noise
float noise(vec2 p){
  vec2 ip = floor(p);
  vec2 u = fract(p);
  u = u*u*(3.0-2.0*u);

  float res = mix(
      mix(rand(ip), rand(ip+vec2(1.0,0.0)), u.x),
      mix(rand(ip+vec2(0.0,1.0)), rand(ip+vec2(1.0,1.0)), u.x),
      u.y);
  return res*res;
}

// fractal gas noise
float fbm(vec2 p){
  float f = 0.0;
  f += 0.5000 * noise(p); p = p*2.02;
  f += 0.2500 * noise(p); p = p*2.03;
  f += 0.1250 * noise(p); p = p*2.01;
  f += 0.0625 * noise(p);
  return f;
}

void main(){
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  float t = u_time * 0.15;

  float gas = fbm(uv * 4.0 + vec2(t * 0.8, t * 0.3));
  float gas2 = fbm(uv * 3.0 - vec2(t * 0.4, t * 0.9));

  float finalGas = (gas + gas2) * 0.8;

  vec3 color = vec3(0.1, 1.0, 0.4) * finalGas;

  gl_FragColor = vec4(color, finalGas + 0.2);
}
