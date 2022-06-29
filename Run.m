function Run(subj,varargin)
    assignin('base','args',varargin);
    assignin('base','subj',subj);
    evalin('base','runSubjScript');
end
