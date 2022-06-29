classdef STable < handle & matlab.mixin.CustomDisplay
% STable for experiment progress
% SubjInfo for subject params
properties(Hidden)
    Table
end
methods(Static)
    function [obj,bWarn]=load();
        obj=STable();
        fname=obj.get_fname();
        if Fil.exist(fname)
            obj.Table=Table.load(fname);
        else
            bWarn=true;
            Error.warnSoft(['STable does not exist. Creating new']);
            key={'subj','name','mode'};
            types={'char','char','double'};
            obj.Table=Table([],key,types);
        end
    end
    function moude=getMode(subj,name)
        obj=STable.load();
        moude=obj.get_mode(subj,name);
    end
    function changeMode(subj,name,moude)
        obj=STable.load();
        obj.Table('subj',subj,'name',name,'mode')=moude;
        obj.save();
    end
end
methods
    function obj=save(obj);
        fname=obj.get_fname();
        obj.Table.save(fname);
    end
    function addSubj(obj,subj,name)
        tbl=[obj.Table{'subj','name'}];
        if size(tbl,1)==0
            ;
        elseif ismember([subj name], strcat(tbl(:,1), tbl(:,2)))
            Error.warnSoft(['Subj ' subj ' already in table ' name ]);
        end
        obj.Table.add_row('subj',subj,'name',name,'mode',0);
    end
    function moude=get_mode(obj,subj,name)
        moude=obj.Table('subj',subj,'name',name,'mode').ret();
    end
end
methods(Access=private)
    function [tbl,key]=get_base_table(obj)
        key={'mode'};
        tbl=obj.Table.unique(key{:});
    end
end
methods(Access=protected)
    function out=getHeader(obj)
        dim = matlab.mixin.CustomDisplay.convertDimensionsToString(obj.Table);
        name = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
        out=['  ' dim ' ' name newline];
    end
    function out=getFooter(obj)
        out=obj.Table.get_footer();
        %out=' ';
    end
end
methods(Static,Hidden)
    function fname=get_fname(obj)
        fname=[Env.var('EDATA') 'STable.mat'];
    end
end
end
