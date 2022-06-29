function U=EUnits(varargin)
    names=varargin;
    n=length(names);
    key={'meas','units','mult','frmt','name','nabbrev'};
    types={'char','char','double','char','char','char'};
    table=cell(1,length(key));
    for i = 1:n
        switch names{i}
            case 'disparity'
                meas='disparity';
                units='arcmin';
                mult=60;
                frmt='%.2f';
                name='Disparity';
                nabbrev='Disp.';
            case {'bin','bins'}
                meas='bin';
                units='au';
                mult=1;
                frmt='%d';
                name='Bin';
                nabbrev='Bin';
            otherwise
                meas='x';
                units='au';
                mult=1;
                frmt='';
                name='X';
                nabbrev='X';
        end
        table{1}{end+1,1}=meas;
        table{2}{end+1,1}=units;
        table{3}(end+1,1)=mult;
        table{4}{end+1,1}=frmt;
        table{5}{end+1,1}=name;
        table{6}{end+1,1}=nabbrev;
    end
    U=Table(table,key,types);
end
