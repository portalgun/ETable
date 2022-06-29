classdef ETable < handle & matlab.mixin.CustomDisplay
properties
    name
    lvlRule % ordered,rand
    blkRule % ordered,rand
end
properties(Hidden)
    Table = Table() %subj, status, moude,lvlInd,blk
    S
    Blk
end
properties(Hidden)
    bNeedSubjSave=false
end
methods(Static)
    function obj=get(name,varargin)
        if nargin < 1 || isempty(name)
            name=Env.var('ALIAS');
        end
        obj=ETable();
        obj.name=name;
        fname=obj.get_fname();

        S=load(fname);
        obj.Table=Table(S.table,S.key,S.types);
        obj.lvlRule=S.lvlRule;
        obj.blkRule=S.blkRule;
        obj.Blk=Blk.get(obj.name);
        if length (varargin) > 1
            obj.Table=obj.Table(varargin{:});
        end

    end
    function obj=fromBlk(blk,Subj,lvlRule,blkRule)
        if ischar(blk) || isempty(blk)
            alias=blk;
            blk=Blk.get(alias);
        end
        tbl=blk.blk.unique('trl',1,'intrvl',1, 'mode','lvlInd','blk');

        tbl=[{Vec.col(Subj)} 0 tbl 1 0];
        tbl=Set.distribute(tbl{:});
        key={'subj','status','mode','lvlInd','blk','pass','date'};
        types={'char','double','double','double','double','uint8','double'};
        obj=ETable();
        obj.name=blk.alias;
        obj.add_subj_sTable(Subj, blk.alias);
        obj.lvlRule=lvlRule;
        obj.blkRule=blkRule;

        obj.Table=Table(tbl,key,types);
        obj.save(true);

    end
end
methods
%% GET
    function disable_(obj,varargin)
        obj.Table(varargin{:},'status')=-1;
    end
    function enable_(obj,varargin)
        obj.Table(varargin{:},'status')=0;
    end
    function reset_(obj,varargin)
        fnames=obj.get_raw_fnames('status','~=',0,varargin{:});
        bExist=cellfun(@Fil.exist,fnames);
        fnames=fnames(bExist);
        for i =1:length(fnames)
            disp(fnames{i})
        end
        if isempty(fnames)
            disp('Nothing to update');
            return
        end
        out=Input.yn('Delete above files and reset?');
        if ~out
            return
        end
        for i = 1:length(fnames)
            delete(fnames{i});
        end
        obj.Table(varargin{:},'status')=0;
    end
    function test_flag(obj)
        tbl={...
          6, 1;
         11, 1;
         24, 1;
        };
        %tbl={...
        %  6, 1;
        % 11, 1;
        % 16, 2;
        % 24, 1;
        % 19, 4;
        % 14, 3;
        % 14, 4;
        % 6,  1;
        % 6,  2;
        %};

        %B=Blk.get();
        %out=B.lookup.lvl('stdInd',[tbl{:,1}]);

        sz=size(tbl,1);
        subj=repmat({'JDB'},sz,1);
        moude=repmat({1},sz,1);
        pass=repmat({1},sz,1);
        tbl=[subj tbl moude pass];
        keys={'subj','lvlInd','blk','mode','pass'};
        obj.flag_(tbl,keys);
    end
    function flag_(obj,tbl,keys)
        %[keys,vals,posVals,nPosArgs]=Args.partsToKeysVals(varargin{:});

        fnames={};
        nfnames={};
        for i = 1:size(tbl,1);
            vals=tbl(i,:);

            in=[keys; vals];

            F=obj.get_raw_fnames(in{:});
            f=F{1};

            dt=obj.Table{in{:},'date'};
            dt2=Date.unix2human_file(dt);
            nf=[f '__' dt2];

            fnames=[fnames; f];
            nfnames=[nfnames; nf];
        end
        str=strcat(fnames,{' -> '},nfnames);
        disp(str)
        out=Input.yn('Change above files and mark status to 0?');
        if ~out
            return
        end
        for i = 1:length(fnames)
            %F{i}
            vals=tbl(i,:);

            % CHANGE STATUS
            in=[keys; vals];
            obj.Table(in{:},'status')=0;

            % MOVE
            Fil.move(fnames{i},nfnames{i});

            obj.save();
        end
    end
    function add_dates_from_file(obj)
        if ~ismember_cell('date',obj.Table.KEY)
            n=size(obj.Table,1);

            obj.Table.TABLE=[obj.Table.TABLE zeros(size(obj.Table,1),1)];
            obj.Table.KEY=[obj.Table.KEY 'date'];
            obj.Table.types=[obj.Table.types 'double'];
        end
        obj.Table.TABLE
        obj.Table.KEY
        obj.Table.types

        %p={'status','>',0,'date',0};
        %[fnames,names]=obj.get_raw_fnames('status','>',0,'date',0);
        p={'date',0};
        [fnames,names]=obj.get_raw_fnames(0,'date',0);
        bExist=cellfun(@Fil.exist,fnames);
        dates=zeros(size(bExist));
        dates(bExist)=Fil.cdate(fnames(bExist));
        obj.Table('status','>',0,'date',0)
        size(obj.Table('status','>',0,'date',0));
        obj.Table(p{:},'date')=dates

    end
    function add_pass(obj)
        T0=obj.Table;
        if ~ismember_cell('pass',obj.Table.KEY)
            n=size(obj.Table,1);

            obj.Table.TABLE=[obj.Table.TABLE {ones(n,1)}];
            obj.Table.KEY=[obj.Table.KEY 'pass'];
            obj.Table.types=[obj.Table.types 'uint8'];

            T1=obj.Table('mode',1);
            N=2;

        else
            T1=obj.Table('pass',1);
            T1.unique('pass');

            N=max(T0.unique('pass')+1);
        end

        T2=Table();
        T2.TABLE=T1.TABLE;
        T2.KEY=T1.KEY;
        T2.types=T1.types;

        T2('pass',1,'pass')=N;
        T2('status')=-1;
        T2('date')=0;

        obj.Table=[T0; T2];
        %obj.Table('pass',
    end
    function out=lvl2ind(obj,lvls)
        out=obj.Blk.lvl2ind(lvls);
    end
    function [out,names]=ind2lvl(obj,ind)
        out=obj.Blk.ind2lvl(ind);
        names=obj.Blk.lookup.lvl.KEY(2:end);
    end
    function [out,names]=ind2val(obj,ind)
        out=obj.Blk.ind2val(ind);
        names=obj.Blk.lookup.lvl.KEY(2:end);
    end
    function out=lvls(obj,varargin)
        if length(varargin) > 1
            tb=obj.Table(varargin{:});
        else
            tb=obj.Table;
        end
        l=tb{'lvlInd'};
        B=obj.Blk.unique_rows('lvlInd',l,'lvlInd');
        lvlInds=B.blk('lvlInd').ret();
        B=B('lvls');
        lvls=B.blk.ret();

        [~,ind]=ismember(l,lvlInds);
        out=lvls(ind,:);
    end
    function pass=get_current_pass(obj,subj,moude)
        T=obj.Table.unique_rows('mode',moude,'subj',subj,'pass','status');
        ps=[T{:}];
        ps(ps(:,2)>1,2)=0;
        ps=unique(ps,'rows','sorted');
        pass=ps(find(ps(:,2)==0,1,'first'),1);
    end
    function [lvlInd,blk,trial,moude,rsp,pass]=get_next_run(obj,subj,moude,varargin);
        %blkRule
        %lvlRule
        %mode
        %lvlInd

        [pass,varargin,bPass]=Args.getPair('pass',varargin);
        if ~bPass
            %if moude==1
                pass=obj.get_current_pass(subj,moude);
                if isempty(pass)
                    pass=1;
                end
            %else
            %    pass=1;
            %end
        end

        if moude==0
            Error.warnSoft(['Subject ' subj ' needs to be assigned status']);
            lvlInd=[];
            blk=[];
            trial=[];
            rsp=[];
            return
        end
        if length(varargin) >= 1
            B=obj.Blk(varargin{:},'lvlInd');
            lvlInd=B.blk.ret();
            args={'lvlInd' lvlInd};
        else
            args={};
        end
        T=obj.Table('subj',subj,'mode',moude,'status','==',0,'pass',pass,args{:});
        if isempty(T)
            T=obj.Table('subj',subj,'mode',moude,'status','<',1,'pass',pass,args{:});
        end
        mx=max(T('status').ret());
        T=T('status',mx,'lvlInd','blk');

        trial=1;
        if mx > 1
            trial=mx;
        end
        A=T.ret();
        if isempty(obj.lvlRule)
            lvlRule='rand';
        else
            lvlRule=obj.lvlRule;
        end
        if isempty(obj.blkRule)
            blkRule='ordered';
        else
            blkRule=obj.blkRule;
        end

        vals=unique(A(:,1));
        if numel(vals) == 1
            lvlInd=vals;
        else
            N=hist(A(:,1),vals);
            ind=find(N==max(N));
            choices=vals(ind);

            if strcmp(lvlRule,'ordered')
                i=choices(1);
            else
                i=randi(numel(choices));
                lvlInd=choices(i);
            end
        end

        B=T('lvlInd',lvlInd,'blk').ret();
        if strcmp(blkRule,'ordered')
            blk=min( B );
        else
            blk=B(randi(numel(B)));
        end
        if mx > 1
            if nargout >= 5
                rsp=obj.loadRawData('subj',subj,'mode',moude,'lvlInd',lvlInd,'blk',blk,'pass',pass);
            end
        else
            fnames=obj.get_raw_fnames('subj',subj,'mode',moude,'lvlInd',lvlInd,'blk',blk,'pass',pass);
            % CHECK TO SEE DATA FILE DOES NOT EXIST
            if Fil.exist(fnames{1})
                error(['Filename ' fnames{1} ' unexpectedly exists. Probably from previous experiment iteration.'])
            end
            rsp=[];
        end

    end
%% SUBJ
    function add_subj_(obj,subj)
        eSubjs=obj.Table.unique('subj');
        obj.add_subj_sTable(subj,obj.name);
        if ismember(subj,eSubjs)
            error(['Subj ' subj ' is already member' ]);
        end

        [tbl,~]=obj.get_base_table();
        %key={'mode','lvlInd','blk'};
        passes=obj.Table.unique('pass');
        tbl=[{{subj}} 0 tbl passes 0];
        tbl=Set.distribute(tbl{:});
        key={'subj','status','mode','lvlInd','blk','pass','date'};
        tbl=Table(tbl,key);
        out=obj.Table.vertcat(tbl);
        obj.Table=out;
    end
    function rm_subj_(obj,subj)
        subjs=obj.Table.unique('subj');
        if ~ismember(subj,subjs)
            error(['Subj ' subj ' is already not a member' ]);
        end
        subjs(ismember(subjs,subj))=[];
        obj.Table=obj.Table('subj',subjs);
    end
%% DATA
    function saveRawData(obj,data,subj,moude,lvlInd,blk, inds,pass)
        if nargin < 8 || isempty(pass)
            pass=1;
        end
        fnames=obj.get_raw_fnames('subj',subj,'mode',moude,'lvlInd',lvlInd,'blk',blk,'pass',pass);
        if numel(fnames) < 1
            error('Ambiguous options');
        end
        fname=fnames{1};

        if length(data)==0;
            return
        end

        key=data.KEY;
        table=data.TABLE;
        types=data.types;
        infoKey={'subj','mode','lvlInd','blk'};
        info={subj,uint8(moude),uint8(lvlInd),uint8(blk)};
        infoTypes={'char','uint8','uint8','uint8'};
        save(fname,'key','table','types','info','infoKey','infoTypes');

        if numel(inds) > 1
            % SAVE STATUS AS TRIAL
            status=inds(1);
        else
            status=1;
        end

        obj.Table('subj',subj,'mode',moude,'lvlInd',lvlInd,'blk',blk,'status')=status;
        obj.Table('subj',subj,'mode',moude,'lvlInd',lvlInd,'blk',blk,'date')=Time.Sec.unix();
        obj.save();
    end
    function rmData(obj,varargin)
        [fnames,names]=obj.get_raw_fnames(varargin{:});
        fnames=fnames(cellfun(@Fil.exist,fnames));

        if ~isempty(fnames)
            disp(['Remove following files?' newline strjoin(strcat({'  '},strjoin(fnames)),newline)])
            out=Input.yn('');
            if ~out
                return
            end
            for i = 1:length(fnames)
                delete(fnames{i});
            end
        end
        obj.Table(varargin{:},'status')=0;
        obj.Table(varargin{:},'date')=0;
        %obj.Table(varargin{:})
    end
    function out=loadRawData(obj,varargin)
        [fnames,names]=obj.get_raw_fnames(varargin{:});
        bExist=cellfun(@Fil.exist,fnames);
        bDate=ismember('date',obj.Table.KEY);
        if bDate
            dates=obj.Table{varargin{:},'date'};
        end

        if isempty(fnames)
            Error.warnSoft(['No valid filenames returned']);
            return
        elseif ~any(bExist)
            Error.warnSoft(['None of the specified files exist:' newline Str.indent(strjoin(names(~bExist),newline),4)]);
            return
        elseif any(~bExist)
            Error.warnSoft(['Following files do not exist:' newline Str.indent(strjoin(names(~bExist),newline),4)]);
        end
        bFirst=true;
        for i = 1:length(fnames)
            if ~bExist(i)
                i
                continue
            end
            [key,table,types,exitflag]=ETable.load_a_data(fnames{i});
            if exitflag
                continue
            end
            if bDate
                key=[key 'date'];
                types=[types 'double'];
                table{end+1}=repmat(dates(i),size(table{1}));
            end
            if bFirst
                T=table;
                K=key;
                t=types;
                ind=ismember(types,{'char','cell'});
            elseif isequal(K,key)
                %table{ind}
                T=[T; table];
            end
            bFirst=false;
        end
        out=Table(T,K,types);
    end
%% SELF DATA
    function save(obj,bPromptOverwrite)
        if nargin < 2
            bPromptOverwrite=false;
        end
        fname=obj.get_fname();
        if bPromptOverwrite && Fil.exist(fname)
            out=Input.yn(['ETable ' obj.name ' already exists. Overwrite?']);
            if ~out
                return
            end
        end
        table=obj.Table.TABLE;
        key=obj.Table.KEY;
        types=obj.Table.types;
        lvlRule=obj.lvlRule;
        blkRule=obj.blkRule;
        save(fname,'key','table','types','lvlRule','blkRule');

        if obj.bNeedSubjSave
            obj.S.save();
            obj.bNeedSubjSave=false;
        end
    end
    function printStd(obj,lvlInd)
        [lvls,names]=obj.ind2val(lvlInd);
        U=EUnits(names{:});
        vals=cellfun(@(x,f,m,u) sprintf([m ' ' f ' ' u],x), ...
            num2cell(Vec.col(lvls).*([U{'mult'}])), ...
            [U{'frmt'}], ...
            [U{'meas'}], ...
            [U{'units'}], ...
            'UniformOutput',false);

        vals=cellfun(@strsplit,vals,'UniformOutput',false);
        vals=[Str.indent(Cell.toStr(vertcat(vals{:}),2),8)];
        disp(vals);

    end
end
methods(Static,Hidden)
    function dire=get_dir()
        dire=Env.var('EDATA');
    end
end
methods(Hidden)
    function varargout=subsref(obj,s)
        switch s(1).type
        case '.'
            [varargout{1:nargout}]= builtin('subsref',obj,s);
        otherwise
            subs=s(1).subs;
            if ~iscell(subs)
                subs={subs};
            end

            K=[obj.Blk.blk.KEY,'lvl','lvls','std','cmp'];
            bInd=cellfun(@(x) ischar(x) && ismember(x,K),subs);
            nInd=cellfun(@isnumeric,subs);

            bb=[false bInd];
            bb(end)=[];
            ind=(nInd & bb) | bInd;

            if any(ind)
               sb=s(1);
               sb.subs=sb.subs(ind);
               sb.subs{end+1}='lvlInd';
               B= builtin('subsref',obj.Blk,sb);
               lvlInd=B.blk.unique('lvlInd');
               s(1).subs{end+1}='lvlInd';
               s(1).subs{end+1}=lvlInd;
               subs=s(1).subs;
            end
            K=obj.Table.KEY;
            bInd=cellfun(@(x) ischar(x) && ismember(x,K),subs);
            nInd=cellfun(@isnumeric,subs);

            bb=[true bInd];
            bb(end)=[];
            ind=(nInd & bb) | bInd;

            if any(ind)
               out=Obj.copy(obj);
               sb=s(1);
               sb.subs=sb.subs(ind);
               out.Table= builtin('subsref',obj.Table,sb);
            end
            if length(s) > 1
                out=out.subsref(s(2:end));
            end
            [varargout{1:nargout}]=out;
        end
    end
    function rm_ETable(obj)
        fname=obj.get_fname();
        out=Input.yn(['Are you sure you want to delete ' obj.name ' ETable?']);
        if ~out
            return
        end
        delete(fname);
    end
    function fname=get_fname(obj)
        fname=[obj.get_dir obj.name '.mat'];
    end
    function [fnames,names,out,outKeys]=get_raw_fnames(obj,varargin)
        outKeys={'subj','mode','lvlInd','blk'};
        N=4;
        if ismember_cell('pass',obj.Table.KEY)
            outKeys=[outKeys 'pass'];
            N=5;
        end
        [out{1:N}]=obj.Table(varargin{:},outKeys{:}).ret();
        nums=num2cell(horzcat(out{2:end}));
        subj=out{1};

        names=cell(size(nums,1),1);
        for i = 1:size(nums,1)
            names{i}=obj.get_raw_name(subj{i},nums{i,:});
        end
        fnames=strcat(Env.var('DATA'),'raw',filesep,names);
    end
    function names=get_raw_name(obj,subj,moude,lvlInd,blk,pass)
        if nargin < 6 || isempty(pass) || pass==1
            blkID=sprintf('%s-%d-%03d-%03d',subj,moude,lvlInd,blk);
        else
            blkID=sprintf('%s-%d-%03d-%03d--%d',subj,moude,lvlInd,blk,pass);
        end
        names=[ obj.name '_' blkID '.mat'];
    end
    function n=length(obj)
        n=length(obj.Table);
    end
end
methods(Access=protected)
    function add_subj_sTable(obj,subjs,alias)
        if ~iscell(subjs)
            subjs={subjs};
        end
        obj.S=STable.load();
        for i = 1:length(subjs)
            subj=subjs{i};
            if length(obj.S.Table('subj',subj,'name',alias)) < 1
            %if ~ismember(subj,obj.S.Table{'subj'})
                obj.S.addSubj(subj,obj.name);
                obj.bNeedSubjSave=true;
            end
        end
    end
    function out=displayEmptyObject(obj)
        display([obj.getHeader() newline obj.getFooter()]);
    end
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
methods(Static,Access=protected)
    function [key,table,types,exitflag]=load_a_data(fname)
        S=load(fname);

        % EXPAND
        key=[S.key S.infoKey];
        n=size(S.table{1},1);
        for i = 1:length(S.info)
            if ischar(S.info{i});
                S.info{i}={S.info{i}};
            end
        end
        if ~ismember('pass',key)
            pass=ETable.pass_from_fname(fname);
            S.info{end+1}=pass;
            key{end+1}='pass';
            if isfield(S,'infoTypes')
                S.infoTypes{end+1}='double';
            end
        end
        R=cellfun(@(x) repmat(x,n,1),S.info,'UniformOutput',false);

        bGd=checkInfo(key(end-3:end), S.info(2:end), fname);
        exitflag=~bGd;
        table=[S.table R];

        if ~isfield(S,'infoTypes')
            S.infoTypes={'char','uint8','uint8','uint8','double'};
        end
        types=[S.types S.infoTypes];
        function bGd=checkInfo(key,info,fname)

            [fInfo,fKey]=ETable.split_fname(fname);

            rmind=~ismember(fKey,key);
            fInfo(rmind)=[];
            fKey(rmind)=[];

            % SORT info like FInfo
            [~,fInd]=sort(fKey);
            [~,revInd]=sort(fInd);
            [~,ind]=sort(key);
            info=info(ind);
            info=info(revInd);

            bSame=cellfun(@isequal,fInfo,info);
            bGd=~any(~bSame);
            if ~bGd
                badKeys=fKey(~bSame);
                badInfo=info(~bSame);
                for i = 1:length(badInfo)
                    if isnumeric(badInfo{i})
                        badInfo{i}=num2str(badInfo{i});
                    end
                end
                bad=strjoin(strcat({'    '},badKeys,{' '},badInfo),newline);
                [~,name]=Fil.parts(fname);
                str=sprintf('%s has unmatching info:\n %s',name,bad);
                Error.warnSoft(str);
            end
        end
    end
    function out=fnameKey()
        out={'alias','subj','mode','lvlInd','blk','pass'};
    end
    function [out,key]=split_fname(fname)
        [~,name]=Fil.parts(fname);
        re='[\-_]+';
        spl=strsplit(name,re,'CollapseDelimiters', false,'DelimiterType', 'RegularExpression');
        if numel(spl)==5
            spl=[spl '1'];
        elseif ~numel(spl)==6
            error();
        end
        key=ETable.fnameKey;
        numTypes={'mode','lvlInd','blk','pass'};
        nInd=ismember_cell(key,numTypes);
        spl(nInd)=cellfun(@str2double,spl(nInd),'UniformOutput',false);
        out=spl;

    end
    function pass=pass_from_fname(fname)
        passn=regexp(fname,'.*--([0-9])\.mat','tokens','once');
        if isempty(passn)
            pass=1;
        else
            pass=str2double(passn{1});
        end
    end
end
methods(Access=private)
    function [tbl,key]=get_base_table(obj)
        key={'mode','lvlInd','blk'};
        tbl=obj.Table.unique(key{:});
    end
end
end
