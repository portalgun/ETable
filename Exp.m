classdef Exp < handle
properties
    name
    ETable
    STable
end
properties(Hidden)
    bGlobal=false
end
methods
    function obj=Exp(alias)
        global EXP_TABLES;
        bGlobal=false;
        if nargin < 1
            alias=Env.var('ALIAS');
            bGlobal=true;
        end
        obj.name=alias;
        obj.ETable=ETable.get(alias);
        obj.STable=STable.load();
        if bGlobal
            obj.bGlobal=true;
            EXP_TABLES=obj;
            assignin('base','Exp',obj);
        end
    end
    function reload(obj)
        obj.ETable=ETable.get(obj.name);
        obj.STable=STable.load();
    end
    function obj=enable(obj,varargin)
        obj.ETable.enable_(varargin{:},'status',-1);
        obj.ETable.save();
    end
    function obj=disable(obj,varargin)
        obj.ETable.disable_(varargin{:},'status','~=',1);
        obj.ETable.save();
    end
    function reset(obj,varargin)
        obj.ETable.reset_(varargin{:});
        obj.ETable.save();
    end
    function addSubj(obj,subj)
        obj.ETable.add_subj_(subj);
        obj.ETable.save();
    end
    function addPass(obj)
        obj.ETable.add_pass();
        %obj.ETable.save();
    end
    function renameSubj(obj,subj,nsubj)
        out=obj.STable.Table{'subj',subj,'subj'};
        if ~isempty(out) > 0
            obj.STable.Table('subj',subj,'subj')=nsubj;
        end
        out=obj.ETable.Table{'subj',subj,'subj'};
        if ~isempty(out)
            obj.ETable.Table('subj',subj,'subj')=nsubj;
        end
    end
    function [lvlInd,blk,trial,moude,rsp,pass]=getNextRun(obj,subj,varargin)
        [moude,varargin]=obj.get_mode(subj,varargin{:});
        [lvlInd,blk,trial,moude,rsp,pass]=obj.ETable.get_next_run(subj,moude,varargin{:});
    end
    function changeMode(obj,subj,moude)
        obj.STable.changeMode(subj,obj.name,moude);
        obj.STable.save();
    end
    function moude=status(subj)
        m=obj.STable.get_mode(subj,obj.name);
        if nargout < 1
            switch m
                case 0
                    disp('none')
                case 1
                    disp('experiment')
                case 2
                    disp('pilot')
                case 3
                    disp('train')
            end
        else
            moude=m;
        end
    end
    function [moude,varargin]=get_mode(obj,subj,varargin)
        [moude,varargin]=Args.getPair('moude',varargin{:});
        if isequal(moude,0)
            [moude,varargin]=Args.getPair('mode',varargin{:});
        end
        if isequal(moude,0)
            moude=obj.STable.get_mode(subj,obj.name);
        end
    end
    function ind=lvl2ind(obj,lvls)
        ind=obj.ETable.lvl2ind(lvls);
    end
    function lvl=ind2lvl(obj,ind)
        lvl=obj.ETable.ind2lvl(ind);
    end
    function [N,n]=completion(obj,varargin)
        if nargin < 2
            T=obj.ETable;
        else
            T=obj.ETable.Table(varargin{:});
        end
        Nn=length(T('status','~=',-1));
        nn=length(T('status',1));
        if nargout > 0
            N=Nn;
            n=nn;
        else
            fprintf('%d / %d\n',nn,Nn);
        end
    end
    function print(obj,subj,moude,lvlInd,blk,blkAlias,pass)
        if nargin >= 6 && ~isempty(blkAlias)
            fprintf('\nBlk     %s\n',blkAlias);
        end
        if nargin < 7 || isempty(pass)
            pass=1;
        end
        lvls=Num.toStr(obj.ind2lvl(lvlInd));
        fprintf('E       %s\nSubj.   %s \nMoude   %d\nLvls    %s : %d\n',obj.name,subj,moude,lvls,lvlInd);
        obj.ETable.printStd(lvlInd);
        fprintf('Block   %d\nPass    %d\n\n',blk,pass);
    end
end
methods(Static)
    function out=ls(~)
        dire=ETable.get_dir();
        names=strrep(Fil.find(dire,'.*\.mat',1),'.mat','');
        names(ismember(names,'STable'))=[];
        if nargout < 1
             cellfun(@disp,names);
        else
            out=names;
        end
    end
end
end
