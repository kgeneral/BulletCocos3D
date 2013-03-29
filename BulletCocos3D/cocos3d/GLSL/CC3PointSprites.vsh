/*
 * CC3PointSprites.vsh
 *
 * cocos3d 2.0.0
 * Author: Bill Hollings
 * Copyright (c) 2011-2013 The Brenwill Workshop Ltd. All rights reserved.
 * http://www.brenwill.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * http://en.wikipedia.org/wiki/MIT_License
 */

/**
 * This vertex shader handles point sprites.
 *
 * This vertex shader can be paired with the following fragment shaders:
 *   - CC3PointSprites.fsh
 *   - CC3PointSpritesWithAlphaTest.fsh
 *
 * The semantics of the variables in this shader can be mapped using a
 * CC3GLProgramSemanticsByVarName instance.
 */

// Increase these if more lights are desired. In order to improve performance, it has been
// kept low to limit the number of uniforms. This definition should not be set larger than
// the CC3GLProgramSemanticsByVarName class-side property maxDefaultMappingLightVariables
// (defaults to 4). See the description of those properties for more info.
#define MAX_LIGHTS				3

// Maximum bones per skin section (batch). This is set here to the platform maximum.
// You can reduce this to improve efficiency if your models need fewer bones in each batch.
#define MAX_BONES_PER_VERTEX	11

precision mediump float;


//-------------- STRUCTURES ----------------------

/**
 * The parameters that define the material covering this vertex.
 *
 * When using this structure as the basis of a simpler implementation, you can remove any elements
 * that your shader does not use, to reduce the number of uniforms that need to be retrieved and
 * pased to your shader (uniform structure elements are passed individually in GLSL), or you can
 * leave them in for clarity, and let the compiler optimize them away.
 */
struct Material {
	vec4	ambientColor;						/**< Ambient color of the material. */
	vec4	diffuseColor;						/**< Diffuse color of the material. */
	vec4	specularColor;						/**< Specular color of the material. */
	vec4	emissionColor;						/**< Emission color of the material. */
	float	shininess;							/**< Shininess of the material. */
	float	minimumDrawnAlpha;					/**< Minimum alpha value to be drawn, otherwise fragment will be discarded. */
};

/**
 * The parameters that define a single light.
 *
 * When using this structure as the basis of a simpler implementation, you can remove any elements
 * that your shader does not use, to reduce the number of uniforms that need to be retrieved and
 * pased to your shader (uniform structure elements are passed individually in GLSL), or you can
 * leave them in for clarity, and let the compiler optimize them away.
 */
struct Light {
	vec4	positionEyeSpace;				/**< Position or normalized direction in eye space. */
	vec4	positionModel;					/**< Position or normalized direction in the local coords of the model. */
	vec4	ambientColor;					/**< Ambient color of light. */
	vec4	diffuseColor;					/**< Diffuse color of light. */
	vec4	specularColor;					/**< Specular color of light. */
	vec3	attenuation;					/**< Coefficients of the attenuation equation. */
	vec3	spotDirectionEyeSpace;			/**< Direction if spotlight in eye space. */
	float	spotExponent;					/**< Directional attenuation factor if spotlight. */
	float	spotCutoffAngleCosine;			/**< Cosine of spotlight cutoff angle. */
	bool	isEnabled;						/**< Whether light is enabled. */
};

/**
 * The parameters to use when displaying vertices as points.
 *
 * When using this structure as the basis of a simpler implementation, you can remove any elements
 * that your shader does not use, to reduce the number of uniforms that need to be retrieved and
 * pased to your shader (uniform structure elements are passed individually in GLSL), or you can
 * leave them in for clarity, and let the compiler optimize them away.
 */
struct Point {
	float	size;							/**< Default size of points, if not specified per-vertex. */
	float	minimumSize;					/**< Minimum size to which points will be allowed to shrink. */
	float	maximumSize;					/**< Maximum size to which points will be allowed to grow. */
	vec3	sizeAttenuation;				/**< Coefficients of the size attenuation equation. */
	float	sizeFadeThreshold;				/**< Alpha fade threshold for smaller points. */
	bool	isDrawingPoints;				/**< Whether the vertices are being drawn as points. */
	bool	hasVertexPointSize;				/**< Whether vertex point size attribute is available. */
	bool	shouldDisplayAsSprites;			/**< Whether points should be interpeted as textured sprites. */
};


//-------------- UNIFORMS ----------------------

// Environment matrices
uniform mat4 u_cc3MtxModelView;				/**< Current modelview matrix. */
uniform mat3 u_cc3MtxModelViewInvTran;		/**< Inverse-transpose of current modelview rotation matrix. */
uniform highp mat4 u_cc3MtxProj;			/**< Projection matrix. */

// Material properties
uniform vec4 u_cc3Color;					/**< Color when lighting & materials are not in use. */
uniform Material u_cc3Material;				/**< The material being applied to the mesh. */

// Lighting properties
uniform bool u_cc3IsUsingLighting;			/**< Indicates whether any lighting is in use. */
uniform vec4 u_cc3SceneLightColorAmbient;	/**< Ambient light color of the scene. */
uniform Light u_cc3Lights[MAX_LIGHTS];		/**< Array of lights. */

// Uniforms describing vertex attributes.
uniform bool u_cc3HasVertexNormal;			/**< Whether vertex normal attribute is available. */
uniform bool u_cc3ShouldNormalizeNormal;	/**< Whether vertex normals should be normalized. */
uniform bool u_cc3ShouldRescaleNormal;		/**< Whether vertex normals should be rescaled. */
uniform bool u_cc3HasVertexColor;			/**< Whether vertex color attribute is available. */
uniform Point u_cc3Points;					/**< Point parameters. */


//-------------- VERTEX ATTRIBUTES ----------------------
attribute highp vec4 a_cc3Position;			/**< Vertex position. */
attribute vec3 a_cc3Normal;					/**< Vertex normal. */
attribute vec4 a_cc3Color;					/**< Vertex color. */
attribute float a_cc3PointSize;				/**< Vertex point size. */

//-------------- VARYING VARIABLE OUTPUTS ----------------------
varying lowp vec4 v_color;					/**< Fragment base color. */
varying highp float v_distEye;				/**< Fragment distance in eye coordinates. */

//-------------- CONSTANTS ----------------------
const vec3 kVec3Zero = vec3(0.0);
const vec4 kVec4Zero = vec4(0.0);
const vec3 kAttenuationNone = vec3(1.0, 0.0, 0.0);
const vec3 kHalfPlaneOffset = vec3(0.0, 0.0, 1.0);

//-------------- LOCAL VARIABLES ----------------------
highp vec4 vtxPosEye;		/**< The vertex position in eye coordinates. High prec to match vertex attribute. */
vec3 vtxNormEye;			/**< The vertex normal in eye coordinates. */
vec4 matColorAmbient;		/**< Ambient color of material...from either material or vertex colors. */
vec4 matColorDiffuse;		/**< Diffuse color of material...from either material or vertex colors. */


//-------------- FUNCTIONS ----------------------

/** Transforms the vertex position and normal to eye space. Sets the vtxPosEye and vtxNormEye variables. */
void vertexToEyeSpace() {
	vtxPosEye = u_cc3MtxModelView * a_cc3Position;
	vtxNormEye = u_cc3MtxModelViewInvTran * a_cc3Normal;
}

/** 
 * Returns the portion of vertex color attributed to illumination of the material by the light at the
 * specified index, taking into consideration attenuation due to distance and spotlight dispersion.
 *
 * The use of highp on the floats is required due to the sensitivity of the calculations.
 * Compiler can crash when attempting to cast back and forth.
 */
vec4 illuminateWith(int ltIdx) {
	highp vec3 ltDir;
	highp float intensity = 1.0;
	
	if (u_cc3Lights[ltIdx].positionEyeSpace.w != 0.0) {
		// Positional light. Find the direction from vertex to light.
		ltDir = (u_cc3Lights[ltIdx].positionEyeSpace - vtxPosEye).xyz;
		
		// Calculate intensity due to distance attenuation (must be performed in high precision)
		if (u_cc3Lights[ltIdx].attenuation != kAttenuationNone) {
			highp float ltDist = length(ltDir);
			highp vec3 distAtten = vec3(1.0, ltDist, ltDist * ltDist);
			highp float distIntensity = 1.0 / dot(distAtten, u_cc3Lights[ltIdx].attenuation);	// needs highp
			intensity *= min(abs(distIntensity), 1.0);
		}
		ltDir = normalize(ltDir);
		
		// Determine intensity due to spotlight component
		highp float spotCutoffCos = u_cc3Lights[ltIdx].spotCutoffAngleCosine;
		if (spotCutoffCos >= 0.0) {
			highp vec3  spotDirEye = u_cc3Lights[ltIdx].spotDirectionEyeSpace;
			highp float cosEyeDir = -dot(ltDir, spotDirEye);
			if (cosEyeDir >= spotCutoffCos){
				highp float spotExp = u_cc3Lights[ltIdx].spotExponent;
				intensity *= pow(cosEyeDir, spotExp);
			} else {
				intensity = 0.0;
			}
		}
    } else {
		// Directional light. Vector is expected to be normalized!
		ltDir = u_cc3Lights[ltIdx].positionEyeSpace.xyz;
    }
	
	// If no light intensity, short-circuit and return no color
	if (intensity <= 0.0) return kVec4Zero;
	
	// Employ lighting equation to calculate vertex color
	vec4 vtxColor = (u_cc3Lights[ltIdx].ambientColor * matColorAmbient);
	vtxColor += (u_cc3Lights[ltIdx].diffuseColor * matColorDiffuse * max(0.0, dot(vtxNormEye, ltDir)));
	
	// Project normal onto half-plane vector to determine specular component
	float specProj = dot(vtxNormEye, normalize(ltDir + kHalfPlaneOffset));
	if (specProj > 0.0) {
		vtxColor += (pow(specProj, u_cc3Material.shininess) *
					 u_cc3Material.specularColor *
					 u_cc3Lights[ltIdx].specularColor);
	}

	// Return the attenuated vertex color
	return vtxColor * intensity;
}

/**
 * Returns the vertex color by starting with material emission and ambient scene lighting,
 * and then illuminating the material with each enabled light.
 */
vec4 illuminate() {
	vec4 vtxColor = u_cc3Material.emissionColor + (matColorAmbient * u_cc3SceneLightColorAmbient);

	for (int ltIdx = 0; ltIdx < MAX_LIGHTS; ltIdx++)
		if (u_cc3Lights[ltIdx].isEnabled) vtxColor += illuminateWith(ltIdx);
	
	vtxColor.a = matColorDiffuse.a;
	
	return vtxColor;
}

/** 
 * If this vertices are being drawn as points, returns the size of the point for the current vertex.
 * If the size is not needed, or if the size cannot be determined, returns the value one.
 */
float pointSize() {
	float size = 1.0;
	if (u_cc3Points.isDrawingPoints) {
		size = u_cc3Points.hasVertexPointSize ? a_cc3PointSize : u_cc3Points.size;
		if (u_cc3Points.sizeAttenuation != kAttenuationNone && u_cc3Points.sizeAttenuation != kVec3Zero) {
			float ptDist = length(vtxPosEye.xyz);
			vec3 attenuationEquation = vec3(1.0, ptDist, ptDist * ptDist);
			size /= sqrt(dot(attenuationEquation, u_cc3Points.sizeAttenuation));
		}
		size = clamp(size, u_cc3Points.minimumSize, u_cc3Points.maximumSize);
	}
	return size;
}

//-------------- ENTRY POINT ----------------------
void main() {

	// If vertices have individual colors, use them for ambient and diffuse material colors.
	matColorAmbient = u_cc3HasVertexColor ? a_cc3Color : u_cc3Material.ambientColor;
	matColorDiffuse = u_cc3HasVertexColor ? a_cc3Color : u_cc3Material.diffuseColor;

	// Transform vertex position and normal to eye space, in vtxPosEye and vtxNormEye, respectively,
	// and use these to set the varying distance to the vertex in eye space.
	vertexToEyeSpace();
	v_distEye = length(vtxPosEye.xyz);
	
	// Determine the color of the vertex by applying material & lighting, or using a pure color
	if (u_cc3IsUsingLighting && u_cc3HasVertexNormal) {
		// Transform vertex normal using inverse-transpose of modelview and renormalize if needed.
		if (u_cc3ShouldRescaleNormal) vtxNormEye = normalize(vtxNormEye);	// TODO - rescale without having to normalize
		if (u_cc3ShouldNormalizeNormal) vtxNormEye = normalize(vtxNormEye);

		v_color = illuminate();
	} else {
		v_color = u_cc3HasVertexColor ? a_cc3Color : u_cc3Color;
	}
	
	gl_Position = u_cc3MtxProj * vtxPosEye;
	
	gl_PointSize = pointSize();
}

