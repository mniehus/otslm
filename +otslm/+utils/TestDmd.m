classdef TestDmd < otslm.utils.TestShowable
% Non-physical dmd-like device for testing code.
% Inherits from :class:`TestShowable`.
%
% This class can be used as a non-physical Showable device in
% simulating a binary amplitude device, such as a digital
% micro-mirror device.
%
% When ``showRaw`` is called, the function calculates the pattern,
% optionally by applying ``rpack`` using the :func:`otslm.tools.finalize`
% method, and sets the ``pattern`` property with the computed pattern. The
% incident illumination is added to the output. To change the incident
% illumination, either set a different pattern on construction or change
% the property value.
%
% Properties
%  - incident (complex) -- incident illumination profile.
%    Must be the same size as the device.
%  - pattern (comples)  -- pattern generated by the ``showRaw`` method.
%    This pattern is is the complex amplitude after multiplying by the
%    incident illumination and applying ``rpack``. The ``rpack`` operation
%    means that this pattern is larger than the device, with extra padding
%    added to the corners.
%  - use_rpack (logical) -- True if ``rpack`` should be used.
%
% Constant properties
%  - size (size) -- device resolution (pixels) [rows, columns]
%  - valueRange  -- range of raw device values (fixed: ``{[0, 1]}``)
%  - patternType -- type of pattern for device (fixed: ``'amplitude'``)
%  - lookupTable -- mapping between gray-scale and binary values. (fixed)
%
% See also TestDmd, :class:`TestSlm` and :class:`TestFarfield`.

% Copyright 2018 Isaac Lenton
% This file is part of OTSLM, see LICENSE.md for information about
% using/distributing this file.

  properties
    incident        % Incident illumination profile
  end

  properties (SetAccess=protected)
    pattern         % Pattern currently displayed on the device
    use_rpack       % True if rpack should be used by show

    valueRange = {0:1};
    lookupTable
    patternType = 'amplitude';
  end
  
  properties (Dependent)
    size            % Size before rotation packing
  end

  methods
    function slm = TestDmd(varargin)
      % Create a new virtual DMD object for testing
      %
      % Usage
      %   slm = TestDmd(...) create a virtual binary amplitude device.
      %
      % Optional named arguments
      %   - size      [row, col] -- Size of the device (default: [512,512])
      %   - incident      im     -- Incident illumination (default: [])
      %   - use_rpack (logical)  -- If ``rpack`` should be used.

      % Parse inputs
      p = inputParser;
      p.addParameter('incident', []);
      p.addParameter('size', [512, 512]);
      p.addParameter('use_rpack', true, @(x) islogical(x));
      p.parse(varargin{:});
      
      % Call base constructor
      slm = slm@otslm.utils.TestShowable();
      
      % Store value range and size
      our_size = p.Results.size;
      
      % Default argument for incident
      if isempty(p.Results.incident)
        slm.incident = ones(our_size);
      else
        slm.incident = p.Results.incident;
      end
      
      % Default argument for lookup table
      value = slm.linearValueRange('structured', true).';
      slm.lookupTable = otslm.utils.LookupTable(...
          [0; 1], value, 'range', 1);
        
      slm.use_rpack = p.Results.use_rpack;
      
      % Show the device, ensures pattern is initialized
      slm.show();
    end
    
    function showRaw(slm, pattern)
      
      % Handle default argument
      if nargin == 1
        pattern = ones(slm.size);
      end
      
      % Pack pattern with 45 degree rotation
      if slm.use_rpack
        rpack_option = {'rpack', '45deg'};
      else
        rpack_option = {'rpack', 'none'};
      end
      
      pattern = otslm.tools.finalize(pattern, rpack_option{:}, ...
          'colormap', 'gray', 'modulo', 'none');
      incident = otslm.tools.finalize(slm.incident, rpack_option{:}, ...
          'colormap', 'gray', 'modulo', 'none');

      % Make the pattern complex and add incident light
      slm.pattern = complex(pattern .* incident);
    end
    
    function set.incident(slm, newincident)
      % Check the new incident pattern
      assert(ismatrix(newincident), 'Incident pattern must be matrix');
      slm.incident = newincident;
    end
    
    function sz = get.size(slm)
      % Get the size of the device (i.e. the incident image)
      sz = size(slm.incident);
    end
  end

end
