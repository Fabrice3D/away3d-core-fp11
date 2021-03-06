package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.core.managers.CubeTexture3DProxy;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.utils.CubeMap;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	use namespace arcane;

	/**
	 * EnvMapDiffuseMethod provides a diffuse shading method that uses a diffuse irradiance environment map to
	 * approximate global lighting rather than lights.
	 */
	public class EnvMapDiffuseMethod extends BasicDiffuseMethod
	{
		private var _cubeTexture : CubeTexture3DProxy;
		private var _cubeMapIndex : int;

		/**
		 * Creates a new EnvMapDiffuseMethod object.
		 * @param envMap The cube environment map to use for the diffuse lighting.
		 */
		public function EnvMapDiffuseMethod(envMap : CubeMap)
		{
			_cubeTexture = new CubeTexture3DProxy();
			_cubeTexture.cubeMap = envMap;
		}

		arcane override function reset() : void
		{
			super.reset();
			_cubeMapIndex = -1;
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose(deep : Boolean) : void
		{
			_cubeTexture.dispose(deep);
		}

		/**
		 * The cube environment map to use for the diffuse lighting.
		 */
		public function get envMap() : CubeMap
		{
			return _cubeTexture.cubeMap;
		}

		public function set envMap(value : CubeMap) : void
		{
			_cubeTexture.cubeMap = value;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function set numLights(value : int) : void
		{
			super.numLights = value;
			_needsNormals = true;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(stage3DProxy : Stage3DProxy) : void
		{
			super.activate(stage3DProxy);

			stage3DProxy.setTextureAt(_cubeMapIndex, _cubeTexture.getTextureForContext(stage3DProxy));
		}

//		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
//		{
//			super.deactivate(stage3DProxy);
//
//			stage3DProxy.setTextureAt(_cubeMapIndex, null);
//		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentAGALPreLightingCode(regCache : ShaderRegisterCache) : String
		{
			return "";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCodePerLight(lightIndex : int, lightDirReg : ShaderRegisterElement, lightColReg : ShaderRegisterElement, regCache : ShaderRegisterCache) : String
		{
			return "";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentPostLightingCode(regCache : ShaderRegisterCache, targetReg : ShaderRegisterElement) : String
		{
			var code : String = "";
			var cubeMapReg : ShaderRegisterElement = regCache.getFreeTextureReg();
			var temp : ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();

			code += "tex " + temp + ", " + _normalFragmentReg + ", " + cubeMapReg + " <cube, bilinear,clamp>\n" +
					"add " + temp+".xyz, " + temp+".xyz, " + targetReg+".xyz\n" +
					"sat " + temp+".xyz, " + temp+".xyz\n";

			_cubeMapIndex = cubeMapReg.index;

            if (_useTexture) {
				_diffuseInputRegister = regCache.getFreeTextureReg();
				code += getTexSampleCode(targetReg, _diffuseInputRegister);
			}
			else {
				_diffuseInputRegister = regCache.getFreeFragmentConstant();
				code += "mov " + targetReg + ", " + _diffuseInputRegister + "\n";
			}

			_diffuseInputIndex = _diffuseInputRegister.index;

			code += "mul " + targetReg + ", " + targetReg + ", " + temp + " \n";

			return code;
		}
	}
}
