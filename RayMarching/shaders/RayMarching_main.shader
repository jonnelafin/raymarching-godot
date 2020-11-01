// "ShaderToy Tutorial - Ray Marching Primitives" 
// by Martijn Steinrucken aka BigWings/CountFrolic - 2018
//
// Modified by Elias Eskelinen aka Jonnelafin - 2020
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
shader_type canvas_item;
uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100;
uniform float SURF_DIST = .001;
uniform float iTime;
uniform float bg = 0.;

uniform float fov = 45.0;
uniform vec3 cameraPos = vec3(-5.0, 0.0, 0.0);
uniform vec3 front = vec3(1.0, 0.0, 0.0);
uniform vec3 up = vec3(0.0, 1.0, 0.0);



//varying float float_arr[3] = float[3] (1.0, 0.5, 0.0); // first constructor
varying vec3 items[500];
uniform int editIndex = 0;
uniform bool digesting = false;
uniform bool ready = false;
uniform bool start = false;
uniform vec3 input;


//Items
//t:
//	0 = do not render
//	1 = box
//	2 = sphere
//	3 = donut
//Item 1
uniform int item1_t = 1;
uniform vec3 item1_loc = vec3(0, 0, 0);
uniform vec3 item1_scale = vec3(1,10,1);
//Item 2
uniform int item2_t = 0;
uniform vec3 item2_loc = vec3(0, 0, 0);
uniform vec3 item2_scale = vec3(1,1,1);
//Item 3
uniform int item3_t = 0;
uniform vec3 item3_loc;
uniform vec3 item3_scale;
//Item 4
uniform int item4_t = 0;
uniform vec3 item4_loc;
uniform vec3 item4_scale;
//Item 5
uniform int item5_t = 0;
uniform vec3 item5_loc;
uniform vec3 item5_scale;

float dot2( in vec3 v ) { return dot(v,v); }

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
	vec3 ab = b-a;
    vec3 ap = p-a;
    
    float t = dot(ab, ap) / dot(ab, ab);
    t = clamp(t, 0., 1.);
    
    vec3 c = a + t*ab;
    
    return length(p-c)-r;
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r) {
	vec3 ab = b-a;
    vec3 ap = p-a;
    
    float t = dot(ab, ap) / dot(ab, ab);
    //t = clamp(t, 0., 1.);
    
    vec3 c = a + t*ab;
    
    float x = length(p-c)-r;
    float y = (abs(t-.5)-.5)*length(ab);
    float e = length(max(vec2(x, y), 0.));
    float i = min(max(x, y), 0.);
    
    return e+i;
}

float sdTorus(vec3 p, vec2 r) {
	float x = length(p.xz)-r.x;
    return length(vec2(x, p.y))-r.y;
}

float dBox(vec3 p, vec3 s) {
	return length(max(abs(p)-s, 0.));
}

float udQuad( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d )
{
  vec3 ba = b - a; vec3 pa = p - a;
  vec3 cb = c - b; vec3 pb = p - b;
  vec3 dc = d - c; vec3 pc = p - c;
  vec3 ad = a - d; vec3 pd = p - d;
  vec3 nor = cross( ba, ad );

  return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(dc,nor),pc)) +
     sign(dot(cross(ad,nor),pd))<3.0)
     ?
     min( min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(dc*clamp(dot(dc,pc)/dot2(dc),0.0,1.0)-pc) ),
     dot2(ad*clamp(dot(ad,pd)/dot2(ad),0.0,1.0)-pd) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}

float GetDist(vec3 p) {
    
	vec4 s = vec4(0, 1, 6, 1);
    
    float sphereDist =  length(p-s.xyz)-s.w;
    float planeDist = p.y;
	planeDist = dBox(p-vec3(0, -2, 0), vec3(10,1,10));
    
    float cd = sdCapsule(p, vec3(3, .5, 6), vec3(3, 2.5, 6), .5); 
    float td = sdTorus(p-vec3(0,.5,6), vec2(1.5, .4));
    float bd = dBox(p-vec3(-3.5, 1, 6), vec3(1,.75,1));
    float cyld = sdCylinder(p, vec3(0, .3, 3), vec3(3, .3, 5), .3);
    
	float d = 100000000000000.;
	//d = min(d, planeDist);
    d = min(d, cd);
    //d = min(d, bd);
	
	//Items
	int t_arr[5] = int[5] (item1_t, item2_t, item3_t, item4_t, item5_t); 
    vec3 loc_arr[5] = vec3[5] (item1_loc, item2_loc, item3_loc, item4_loc, item5_loc);
    vec3 scale_arr[5] = vec3[5] (item1_scale, item2_scale, item3_scale, item4_scale, item5_scale);
	for(int i = 0; i < 5; i++){
		int type = t_arr[i];
		vec3 loc = loc_arr[i];
		vec3 scale = scale_arr[i];
		if(type == 1){
			d = min(d, dBox(p-loc, scale));
		}
	}
	
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
	float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
        if(dS<SURF_DIST)
		{ 
			break;
		}
		if(dO>MAX_DIST)
		{
			break;
		}
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
	float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}

//Again, from https://www.shadertoy.com/view/4dt3zn
float softShadow(vec3 ro, vec3 lp, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int maxIterationsShad = 24; 
    
    vec3 rd = lp - ro; // Unnormalized direction ray.

    float shade = 1.;
    float dist = .002;    
    float end = max(length(rd), .001);
    float stepDist = end/float(maxIterationsShad);
    
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i = 0; i<maxIterationsShad; i++){

        float h = GetDist(ro + rd*dist);
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0., 1., k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        // So many options here, and none are perfect: dist += min(h, .2), dist += clamp(h, .01, .2), 
        // clamp(h, .02, stepDist*2.), etc.
        dist += clamp(h, .02, .25);
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (h<0. || dist>end) break; 
        //if (h<.001 || dist > end) break; // If you're prepared to put up with more artifacts.
    }

    // I've added 0.5 to the final shade value, which lightens the shadow a bit. It's a preference thing. 
    // Really dark shadows look too brutal to me.
    return min(max(shade, 0.) + .25, 1.); 
}

float GetLight(vec3 p, vec3 lightPos) {
    //vec3 lightPos = vec3(0, 5, 6);
    //lightPos.xz += vec2(sin(iTime), cos(iTime))*2.;
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*2., l);
    //if(d<length(lightPos-p)) dif *= .1;
    if(d<length(lightPos-p)) dif *= .1;
	//dif *= d-length(lightPos-p)*0.3;
    
    return dif;
}
float traceRef3(vec3 ro, vec3 rd){
	float dO=0.;
    vec3 last;
    for(int i=0; i<MAX_STEPS*100; i++) {
    	vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
		last = p;
        if(dO>MAX_DIST*100.0 || dS<SURF_DIST*1.0) break;
    }
    return GetLight(last, vec3(0,0,0));
    return dO;
}
float traceRef2(vec3 ro, vec3 rd){
	float dO=0.;
    vec3 last;
    for(int i=0; i<MAX_STEPS*100; i++) {
    	vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
		last = p;
        if(dO>MAX_DIST*100.0 || dS<SURF_DIST*1.0) break;
    }
    float ref = 0.;
	if(dO < MAX_DIST * 100.0){
	    vec3 sn = GetNormal(last);
	    rd = reflect(rd, sn);
	    float t = traceRef3(ro +  sn*.003, rd);
		ref = t;
		if(ref < 0.){
			ref = 0.;
		}
		ref = ref * -1.0 + 2.;//traceRef(ro, rd);
	}
    return ref;
}
//from https://www.shadertoy.com/view/4dt3zn
float traceRef(vec3 ro, vec3 rd){
	float dO=0.;
    vec3 last;
    for(int i=0; i<MAX_STEPS*100; i++) {
    	vec3 p = ro + rd*dO;
        float dS = GetDist(p);
        dO += dS;
		last = p;
        if(dO>MAX_DIST*100.0 || dS<SURF_DIST*1.0) break;
    }
    float ref = 0.;
	if(dO < MAX_DIST * 100.0){
	    vec3 sn = GetNormal(last);
	    rd = reflect(rd, sn);
	    float t = traceRef3(ro +  sn*.003, rd);
		ref = t;
		if(ref < 0.){
			ref = 0.;
		}
		ref = ref * -1.0 + 2.;//traceRef(ro, rd);
	}
    return ref;
}


vec3 getRayDirection(vec2 resolution, vec2 uv)
{
	float aspect = resolution.x / resolution.y;
	float fov2 = radians(fov) / 2.0;
	
	// convert coordinates from [0, 1] to [-1, 1]
	// and invert y axis to flow from bottom to top
	vec2 screenCoord = (uv - 0.5) * 2.0;
	screenCoord.x *= aspect;
	screenCoord.y = -screenCoord.y;
	
	vec2 offsets = screenCoord * tan(fov2);
	
	vec3 rayFront = normalize(front);
	vec3 rayRight = normalize(cross(rayFront, normalize(up)));
	vec3 rayUp = cross(rayRight, rayFront);
	vec3 rayDir = rayFront + rayRight * offsets.x + rayUp * offsets.y;
	
	return normalize(rayDir);
}

void fragment()
{
	vec2 uv = UV;//(fragCoord-.5*iResolution.xy)/iResolution.y;

	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec3 col = vec3(0);
    
    vec3 ro = cameraPos;
    vec3 rd = normalize(vec3(uv.x-.15, uv.y-.2, 1));
	rd = getRayDirection(resolution, UV);
    float d = RayMarch(ro, rd);
    vec3 sn = GetNormal(ro);
    
	
    vec3 lightPos = vec3(0, 5, 6);
	vec3 lightPos2 = vec3(-10, 5, -6);
    lightPos.xz += vec2(sin(iTime), cos(iTime))*2.;
	
	//Soft shadows
    //float sh = softShadow(ro +  sn*.0015, lightPos, 16.);
	
    vec3 p = ro + rd * d;
    
    float dif = GetLight(p, lightPos);
	float dif2 = GetLight(p, lightPos2);
    col = vec3(dif + dif2);
	
	//Reflections
    float t = d;//traceRef(ro +  sn*.003, rd);
    
    // Advancing the ray origin, "ro," to the new reflected hit point.
    ro += rd*t;
    
    // Retrieving the normal at the hit point.
     sn = GetNormal(ro);
	
    rd = reflect(rd, sn);
    //t = traceRef(ro +  sn*.003, rd);
	float ref = traceRef(ro +  sn*.003, rd);//traceRef(ro, rd)/2.0; //t * -1.0 + 2.0;
	
    col = pow(col, vec3(.4545));	// gamma correction
    col = ((col*1.0) + vec3(ref*1.0)) / vec3(2);
    //col = vec3(ref);
    COLOR = vec4(col,1.0);
}