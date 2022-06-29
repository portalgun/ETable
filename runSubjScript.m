% CALLED BY 'runSubj'
%Env.var('runner_bLocal');
bLocal=true; % XXX
bXYZ=false; % XXX
bSameWin=false;  % XXX
bSameWdw=true;  % XXX
bPlot=true;

if isempty(bLocal)
    bLocal=false;
end

[alias,args]=Args.getPair('alias',args{:});
if isnumeric(alias)
    alias=Env.var('ALIAS');
end
clear Exp
%if exist('Exp','var')~=1
    Exp=Exp(alias);
%end


[lvlInd,blk,start,moude,rsp,pass]=Exp.getNextRun(subj,args{:});
if isempty(lvlInd)
    display('Experiment complete.');
end

P=ptchs.getBlk(moude,lvlInd,blk,subj,[],alias);
P.bLocal=bLocal;
P.bXYZ=bXYZ;
P.bSameWdw=bSameWdw;
P.bSameWin=bSameWin;

V=PtchsViewer(P,[],true,'exp',true);
setenv('lastSubj',subj)

preStr=sprintf('Running experiment %s as %s.',alias,subj);
while true
    % RUN
    % XXX
    %if ~isempty(rsp)
    %    bSuccess=V.Rsp.apply(rsp);
    %    if ~bSuccess
    %        obj.Error.warnSoft('Unable to apply old Rsp');
    %    end
    %end

    Exp.print(subj,moude,lvlInd,blk,P.Blk.alias,pass);
    V.run(start,[],preStr);
    preStr=[];

    % SAVE
    [tbl,inds]=V.Rsp.finalize();
    if V.returncode ~= -2
        % ALSO UPDATES TABLE
        Exp.ETable.saveRawData(tbl,subj,moude,lvlInd,blk, inds, pass);
    else
        V.PTB.close();
        break
    end

    % EXIT
    if V.returncode==-1
        V.Psy.PTB.sca();
        rethrow(V.ME);
    elseif bPlot
        V.plotting_prompt();
        V.Rsp.plotCurve();
        drawnow
        % SLOW - 10 sec
        %pause(0.005);
    end


    % CONTINUE?
    [lvlInd,blk,start,moude,rsp]=Exp.getNextRun(subj,args{:});
    % .0392

    V.Rsp.sound_correct();
    if isempty(lvlInd)
        obj.make_prompt(['Experiment Complete. ' newline 'Thank you!']);
        display('Experiment complete.');
        pause(3);
        return
    end
    [N,n]=Exp.completion('subj',subj,'mode',moude,args{:});
    str=sprintf('%d / %d\n blocks completed.',n,N);

    V.close_prompt();
    V.continue_prompt(str);
    if V.exitflag
        V.PTB.close();
        break
    end
    V.change_blk(moude,lvlInd,blk);

end
%V.close_prompt();
%V.make_prompt(['    Plotting complete. ' newline 'Determining next run...']);
