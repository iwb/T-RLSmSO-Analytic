classdef List < handle
    %LIST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetAccess = protected)
        Capacity;
        Count;
    end
    
    properties(Access = protected)
        Array;
    end
    
    methods
        function this = List()
            this.Capacity = 10;
            this.Array = nan(1, 10);
            this.Count = 0;
        end
        
        function Add(this, value)
            count = this.Count;
            if (count == this.Capacity)
                this.IncreaseCapacity();
            end
            
            this.Array(count + 1) = value;
            this.Count = count + 1;
        end
        
        function Clear(this)
            this.Count = 0;
            this.Trim();
        end
        
        function Trim(this)
            count = max(this.Count, 10);
            this.Array = this.Array(1:count);
            this.Capacity = count;
        end
        
        function EnsureCapacity(this, capacity)
            if (this.Capacity < capacity)
                this.Array(capacity) = NaN;
            end
        end
        
        function Array = ToArray(this)
            Array = this.Array(1:this.Count);
        end
    end
    
    methods (Access = protected)
        function IncreaseCapacity(this)
            this.Array(this.Capacity * 2) = NaN;
            this.Capacity = this.Capacity * 2;
        end 
    end
end

