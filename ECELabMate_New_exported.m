classdef ECELabMate_New_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        TabGroup                     matlab.ui.container.TabGroup
        ECETutorTab                  matlab.ui.container.Tab
        SpeakAnswerButton            matlab.ui.control.Button
        AnswerTextArea               matlab.ui.control.TextArea
        YouranswerwillappearhereTextAreaLabel  matlab.ui.control.Label
        AnswerLabel                  matlab.ui.control.Label
        AskQuestionButton            matlab.ui.control.Button
        QuestionTextArea             matlab.ui.control.TextArea
        TypeyourelectronicsquestionhereTextAreaLabel  matlab.ui.control.Label
        LanguageDropDown             matlab.ui.control.DropDown
        selectlanguageDropDownLabel  matlab.ui.control.Label
        TitleLabel                   matlab.ui.control.Label
        VirtualLabTab                matlab.ui.container.Tab
        TheoryTextArea               matlab.ui.control.TextArea
        TheoryTextAreaLabel          matlab.ui.control.Label
        TheoryTitleLabel             matlab.ui.control.Label
        GenerateButton               matlab.ui.control.Button
        ExperimentDropDown           matlab.ui.control.DropDown
        ExperimentDropDownLabel      matlab.ui.control.Label
        OutputAxes                   matlab.ui.control.UIAxes
        UIAxes                       matlab.ui.control.UIAxes
        VivaPracticeTab              matlab.ui.container.Tab
        Label                        matlab.ui.control.Label
        ScoreValueLabel              matlab.ui.control.Label
        NextQuestionButton           matlab.ui.control.Button
        VivaFeedbackLabel            matlab.ui.control.Label
        SubmitAnswerButton           matlab.ui.control.Button
        VivaAnswerTextArea           matlab.ui.control.TextArea
        VivaAnswerTextAreaLabel      matlab.ui.control.Label
        VivaQuestionTextArea         matlab.ui.control.TextArea
        VivaQuestionTextAreaLabel    matlab.ui.control.Label
        GenerateQuestionsButton      matlab.ui.control.Button
        SubjectDropDown              matlab.ui.control.DropDown
        SubjectDropDownLabel         matlab.ui.control.Label
        ECELabMateVivaPracticeLabel  matlab.ui.control.Label
    end

    
    properties (Access = private)

    CurrentQuestionIndex = 1;
    TotalScore = 0;
    VivaQuestions = {};
    VivaKeywords = {};
    QuestionsAnswered = 0;
CurrentQuestionScored = false;

end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: AskQuestionButton
        function AskQuestionButtonPushed(app, event)
            

    % Get the question from the Question Text Area
    question = strtrim(strjoin(string(app.QuestionTextArea.Value), ' '));

    % Check whether the question is empty
    if isempty(question)
        app.AnswerTextArea.Value = {'Please enter an electronics question.'};
        return;
    end

    % Get Gemini API key from Windows environment variable
    apiKey = getenv('GEMINI_API_KEY');

    if isempty(apiKey)
        app.AnswerTextArea.Value = {'Gemini API key not found. Please check your environment variable.'};
        return;
    end

    % Display loading message
    app.AnswerTextArea.Value = {'Generating answer using Gemini... Please wait.'};
    drawnow;

    % Get selected language
    selectedLanguage = string(app.LanguageDropDown.Value);

    % Prepare prompt for Gemini
    prompt = sprintf([ ...
        'You are an expert Electronics and Communication Engineering tutor. ' ...
        'Explain the following question in simple, student-friendly language. ' ...
        'Use clear headings, important points, formulas and examples wherever useful. ' ...
        'Keep the explanation suitable for an undergraduate ECE student. ' ...
        'Answer in %s. Question: %s'], ...
        selectedLanguage, question);

    % Gemini API URL
    url = ['https://generativelanguage.googleapis.com/' ...
        'v1beta/models/gemini-3.1-flash-lite:generateContent'];

    % Prepare request data
    data.contents = struct('parts', struct('text', prompt));

    % Configure API request
    options = weboptions( ...
        'MediaType', 'application/json', ...
        'HeaderFields', {'x-goog-api-key', apiKey}, ...
        'Timeout', 60);

    try

        % Send question to Gemini
        response = webwrite(url, data, options);

        % Extract generated answer
        answer = response.candidates(1).content.parts(1).text;

        % Display answer
        app.AnswerTextArea.Value = {char(answer)};

    catch ME

        % Display error message
        app.AnswerTextArea.Value = { ...
            ['Gemini Error: ' ME.message]};

    end











        end

        % Button pushed function: SpeakAnswerButton
        function SpeakAnswerButtonPushed(app, event)
            


    disp('Speak Answer button clicked!');

    % Get generated answer
    answer = strjoin(string(app.AnswerTextArea.Value), newline);

    if isempty(strtrim(answer))
        uialert(app.UIFigure, ...
            'Please generate an answer first.', 'No Answer');
        return;
    end

    % Read API keys
    gnaniKey = getenv('GNANI_API_KEY');
    geminiKey = getenv('GEMINI_API_KEY');

    if isempty(gnaniKey) || isempty(geminiKey)
        uialert(app.UIFigure, ...
            'Gemini or Gnani API key not found.', 'API Error');
        return;
    end

    app.AnswerTextArea.Value = app.AnswerTextArea.Value;
    drawnow;

    try
        % Ask Gemini to create a short speech summary
        geminiURL = ['https://generativelanguage.googleapis.com/' ...
            'v1beta/models/gemini-3.1-flash-lite:generateContent'];

        summaryPrompt = sprintf([ ...
            'Summarize the following ECE explanation for speech. ' ...
            'Use simple language and only 2 to 3 short sentences. ' ...
            'Do not include headings, formulas, markdown or bullet points. ' ...
            'Keep it under 60 words. Explanation: %s'], answer);

        data.contents = struct('parts', ...
            struct('text', summaryPrompt));

        geminiOptions = weboptions( ...
            'MediaType', 'application/json', ...
            'HeaderFields', {'x-goog-api-key', geminiKey}, ...
            'Timeout', 60);

        summaryResponse = webwrite(geminiURL, data, geminiOptions);

        summary = summaryResponse.candidates(1).content.parts(1).text;
        summary = strtrim(char(summary));

        disp('Short summary generated:');
        disp(summary);

        % Send short summary to Gnani
        gnaniURL = 'https://api.vachana.ai/api/v1/tts/inference';

        payload.text = summary;
        payload.model = 'timbre-v2.5';
        payload.voice = 'Kaveri';
        payload.language = 'en-IN';

        payload.audio_config.sample_rate = 48000;
        payload.audio_config.encoding = 'linear_pcm';
        payload.audio_config.container = 'wav';

        body = jsonencode(payload);

        headers = [
            matlab.net.http.HeaderField('Content-Type','application/json'), ...
            matlab.net.http.HeaderField('X-API-Key-ID',gnaniKey)
        ];

        provider = matlab.net.http.io.StringProvider(body);

        request = matlab.net.http.RequestMessage( ...
            'POST', headers, provider);

        uri = matlab.net.URI(gnaniURL);

        options = matlab.net.http.HTTPOptions( ...
            'ConnectTimeout', 30, ...
            'ResponseTimeout', 60);

        response = request.send(uri, options);

        if response.StatusCode == matlab.net.http.StatusCode.OK

            responseData = response.Body.Data;

            audioSamples = double(responseData{1}(:));
            Fs = responseData{2};

            soundsc(audioSamples, Fs);

        else
            disp('Gnani TTS failed:');
            disp(response.Body.Data);

            uialert(app.UIFigure, ...
                'Gnani could not generate speech. Please try again.', ...
                'TTS Error');
        end

    catch ME
        uialert(app.UIFigure, ME.message, 'Speech Error');
    end


    

        end

        % Button pushed function: GenerateButton
        function GenerateButtonPushed(app, event)
         



    % Get selected experiment
    experiment = app.ExperimentDropDown.Value;

    % Clear both graphs
    cla(app.UIAxes);
    cla(app.OutputAxes);

    % ==============================
    % EXPERIMENT 1: AMPLITUDE MODULATION
    % ==============================

    if strcmp(experiment, 'Amplitude Modulation (AM)')

        % Time settings
        t = 0:0.00001:0.05;

        % Signal parameters
        Am = 1;
        Ac = 1;
        fm = 50;
        fc = 500;
        mu = 0.5;

        % Generate message signal
        message = Am*cos(2*pi*fm*t);

        % Generate AM signal
        AM_signal = Ac*(1 + mu*cos(2*pi*fm*t)) ...
            .*cos(2*pi*fc*t);

        % Plot input message signal
        plot(app.UIAxes, t, message, 'r', ...
            'LineWidth', 1.5);

        title(app.UIAxes, 'Input Message Signal');
        xlabel(app.UIAxes, 'Time (seconds)');
        ylabel(app.UIAxes, 'Amplitude');
        grid(app.UIAxes, 'on');
        xlim(app.UIAxes, [0 0.05]);
        ylim(app.UIAxes, [-1.5 1.5]);

        % Plot AM output
        plot(app.OutputAxes, t, AM_signal, 'b', ...
            'LineWidth', 1.2);

        title(app.OutputAxes, 'AM Modulated Output');
        xlabel(app.OutputAxes, 'Time (seconds)');
        ylabel(app.OutputAxes, 'Amplitude');
        grid(app.OutputAxes, 'on');
        xlim(app.OutputAxes, [0 0.05]);
        ylim(app.OutputAxes, [-1.6 1.6]);


        % ==============================
        % EXPERIMENT 2: FREQUENCY MODULATION
        % ==============================

    elseif strcmp(experiment, 'Frequency Modulation (FM)')

        % Time settings
        t = 0:0.00001:0.05;

        % Signal parameters
        Ac = 1;
        fm = 50;
        fc = 500;
        beta = 5;

        % Generate message signal
        message = cos(2*pi*fm*t);

        % Generate FM signal
        FM_signal = Ac*cos(2*pi*fc*t + ...
            beta*sin(2*pi*fm*t));

        % Plot input message signal
        plot(app.UIAxes, t, message, 'r', ...
            'LineWidth', 1.5);

        title(app.UIAxes, 'Input Message Signal');
        xlabel(app.UIAxes, 'Time (seconds)');
        ylabel(app.UIAxes, 'Amplitude');
        grid(app.UIAxes, 'on');
        xlim(app.UIAxes, [0 0.05]);
        ylim(app.UIAxes, [-1.5 1.5]);

        % Plot FM output
        plot(app.OutputAxes, t, FM_signal, 'b', ...
            'LineWidth', 1.2);

        title(app.OutputAxes, 'FM Modulated Output');
        xlabel(app.OutputAxes, 'Time (seconds)');
        ylabel(app.OutputAxes, 'Amplitude');
        grid(app.OutputAxes, 'on');
        xlim(app.OutputAxes, [0 0.05]);
        ylim(app.OutputAxes, [-1.5 1.5]);


        % ==============================
        % EXPERIMENT 3: HALF-WAVE RECTIFIER
        % ==============================

    elseif strcmp(experiment, 'Half Wave Rectifier')

        % Time settings
        t = 0:0.0001:0.1;

        % Signal parameters
        Vm = 5;
        f = 50;

        % Generate AC input
        input_signal = Vm*sin(2*pi*f*t);

        % Half-wave rectification
        output_signal = max(0, input_signal);

        % Plot input signal
        plot(app.UIAxes, t, input_signal, 'r', ...
            'LineWidth', 1.5);

        title(app.UIAxes, 'AC Input Signal');
        xlabel(app.UIAxes, 'Time (seconds)');
        ylabel(app.UIAxes, 'Voltage (V)');
        grid(app.UIAxes, 'on');
        xlim(app.UIAxes, [0 0.1]);
        ylim(app.UIAxes, [-6 6]);

        % Plot rectified output
        plot(app.OutputAxes, t, output_signal, 'b', ...
            'LineWidth', 1.5);

        title(app.OutputAxes, 'Half-Wave Rectified Output');
        xlabel(app.OutputAxes, 'Time (seconds)');
        ylabel(app.OutputAxes, 'Voltage (V)');
        grid(app.OutputAxes, 'on');
        xlim(app.OutputAxes, [0 0.1]);
        ylim(app.OutputAxes, [-1 6]);


        % ==============================
        % EXPERIMENT 4: FULL-WAVE RECTIFIER
        % ==============================

    elseif strcmp(experiment, 'Full Wave Rectifier')

        % Time settings
        t = 0:0.0001:0.1;

        % Signal parameters
        Vm = 5;
        f = 50;

        % Generate AC input
        input_signal = Vm*sin(2*pi*f*t);

        % Full-wave rectification
        output_signal = abs(input_signal);

        % Plot input signal
        plot(app.UIAxes, t, input_signal, 'r', ...
            'LineWidth', 1.5);

        title(app.UIAxes, 'AC Input Signal');
        xlabel(app.UIAxes, 'Time (seconds)');
        ylabel(app.UIAxes, 'Voltage (V)');
        grid(app.UIAxes, 'on');
        xlim(app.UIAxes, [0 0.1]);
        ylim(app.UIAxes, [-6 6]);

        % Plot rectified output
        plot(app.OutputAxes, t, output_signal, 'b', ...
            'LineWidth', 1.5);

        title(app.OutputAxes, 'Full-Wave Rectified Output');
        xlabel(app.OutputAxes, 'Time (seconds)');
        ylabel(app.OutputAxes, 'Voltage (V)');
        grid(app.OutputAxes, 'on');
        xlim(app.OutputAxes, [0 0.1]);
        ylim(app.OutputAxes, [-1 6]);


    else

        uialert(app.UIFigure, ...
            'Please select a valid experiment.', ...
            'Experiment Selection');



    end

   
        end

        % Value changed function: ExperimentDropDown
        function ExperimentDropDownValueChanged(app, event)
     


    experiment = app.ExperimentDropDown.Value;

    switch experiment

        case 'Amplitude Modulation (AM)'

            theory = sprintf([ ...
                'AIM:\n' ...
                'To study Amplitude Modulation.\n\n' ...
                'THEORY:\n' ...
                'Amplitude Modulation is a process in which the ' ...
                'amplitude of a high-frequency carrier signal ' ...
                'varies according to the message signal. ' ...
                'The frequency and phase of the carrier remain constant.\n\n' ...
                'EQUATION:\n' ...
                's(t) = Ac[1 + m cos(wm*t)]cos(wc*t)\n\n' ...
                'MODULATION INDEX:\n' ...
                'm = Am/Ac\n\n' ...
                'APPLICATIONS:\n' ...
                'AM radio broadcasting, communication systems.']);

        case 'Frequency Modulation (FM)'

            theory = sprintf([ ...
                'AIM:\n' ...
                'To study Frequency Modulation.\n\n' ...
                'THEORY:\n' ...
                'In Frequency Modulation, the instantaneous ' ...
                'frequency of the carrier varies according to ' ...
                'the message signal amplitude. Carrier amplitude remains constant.\n\n' ...
                'EQUATION:\n' ...
                's(t) = Ac cos(wc*t + beta sin(wm*t))\n\n' ...
                'MODULATION INDEX:\n' ...
                'beta = delta_f/fm\n\n' ...
                'APPLICATIONS:\n' ...
                'FM radio, wireless communication.']);

        case 'Half Wave Rectifier'

            theory = sprintf([ ...
                'AIM:\n' ...
                'To study the Half Wave Rectifier.\n\n' ...
                'THEORY:\n' ...
                'A half-wave rectifier converts AC into pulsating DC. ' ...
                'It uses one diode and allows only one half-cycle ' ...
                'of the input signal to pass.\n\n' ...
                'OUTPUT:\n' ...
                'Vo = Vm sin(wt), for positive half-cycle.\n' ...
                'Vo = 0, for negative half-cycle.\n\n' ...
                'APPLICATIONS:\n' ...
                'Low-power DC supplies, signal detection.']);

        case 'Full Wave Rectifier'

            theory = sprintf([ ...
                'AIM:\n' ...
                'To study the Full Wave Rectifier.\n\n' ...
                'THEORY:\n' ...
                'A full-wave rectifier converts both positive ' ...
                'and negative half-cycles of AC into pulsating DC.\n\n' ...
                'OUTPUT:\n' ...
                'Vo = abs(Vm sin(wt))\n\n' ...
                'APPLICATIONS:\n' ...
                'DC power supplies, battery charging circuits.']);

        case 'Sampling'

            theory = sprintf([ ...
                'AIM:\n' ...
                'To study the sampling process.\n\n' ...
                'THEORY:\n' ...
                'Sampling converts a continuous-time signal into ' ...
                'a discrete-time signal by taking samples at ' ...
                'regular intervals.\n\n' ...
                'SAMPLING EQUATION:\n' ...
                'x[n] = x(nTs)\n\n' ...
                'NYQUIST CONDITION:\n' ...
                'Fs >= 2Fm\n\n' ...
                'APPLICATIONS:\n' ...
                'Digital signal processing, audio and image processing.']);

        case 'Low Pass Filter'

            theory = sprintf([ ...
                'AIM:\n' ...
                'To study the Low Pass Filter.\n\n' ...
                'THEORY:\n' ...
                'A Low Pass Filter allows low-frequency signals ' ...
                'to pass and attenuates high-frequency signals.\n\n' ...
                'CUTOFF FREQUENCY:\n' ...
                'fc = 1/(2*pi*R*C)\n\n' ...
                'APPLICATIONS:\n' ...
                'Noise reduction, audio processing.']);

        case 'High Pass Filter'

            theory = sprintf([ ...
                'AIM:\n' ...
                'To study the High Pass Filter.\n\n' ...
                'THEORY:\n' ...
                'A High Pass Filter allows high-frequency signals ' ...
                'to pass and attenuates low-frequency signals.\n\n' ...
                'CUTOFF FREQUENCY:\n' ...
                'fc = 1/(2*pi*R*C)\n\n' ...
                'APPLICATIONS:\n' ...
                'Audio systems, noise removal.']);

        otherwise

            theory = 'Select an experiment to display its theory.';

    end

    app.TheoryTextArea.Value = theory;


        
            
        end

        % Button pushed function: GenerateQuestionsButton
        function GenerateQuestionsButtonPushed(app, event)
            


    subject = app.SubjectDropDown.Value;

    switch subject

        case 'Digital Signal Processing'
            questions = {
                'What is DSP?'
                'What is the difference between FIR and IIR filters?'
                'What is FFT?'
                'What is aliasing?'
                'What is the Nyquist sampling theorem?'
                'What is spectral leakage?'
                'What is convolution?'
                'What is correlation?'
                'What is a window function?'
                'What is a stable system?'
            };

        case 'Digital Communication'
            questions = {
                'What is digital communication?'
                'What is ASK modulation?'
                'What is FSK modulation?'
                'What is PSK modulation?'
                'What is DPSK?'
                'What is a Gold sequence?'
                'What is sampling?'
                'What is quantization?'
                'What is PCM?'
                'What is bandwidth?'
            };

        case 'Signals and Systems'
            questions = {
                'What is a continuous-time signal?'
                'What is a discrete-time signal?'
                'What is an even signal?'
                'What is an odd signal?'
                'What is a periodic signal?'
                'What is the Fourier transform?'
                'What is the Laplace transform?'
                'What is a causal system?'
                'What is a linear system?'
                'What is time invariance?'
            };

        case 'Electronic Circuits'
            questions = {
                'What is a diode?'
                'What is a transistor?'
                'What is an amplifier?'
                'What is the operating point?'
                'What is a common emitter amplifier?'
                'What is feedback?'
                'What is an oscillator?'
                'What is a MOSFET?'
                'What is a rectifier?'
                'What is the difference between BJT and FET?'
            };

        case 'Control Systems'
            questions = {
                'What is a control system?'
                'What is an open-loop system?'
                'What is a closed-loop system?'
                'What is transfer function?'
                'What is feedback?'
                'What is stability?'
                'What is damping ratio?'
                'What is natural frequency?'
                'What is a block diagram?'
                'What is a signal flow graph?'
            };

        case 'Digital Electronics'
            questions = {
                'What is a logic gate?'
                'What is a flip-flop?'
                'What is a multiplexer?'
                'What is a demultiplexer?'
                'What is a counter?'
                'What is a shift register?'
                'What is a decoder?'
                'What is a Boolean expression?'
                'What is a Mealy machine?'
                'What is a Moore machine?'
            };

        otherwise
            uialert(app.UIFigure, ...
                'Please select a valid subject.', ...
                'Subject Selection');
            return;
    end

    % Select five random questions
    randomOrder = randperm(length(questions), 5);
    app.VivaQuestions = questions(randomOrder);

    % Initialize the viva session
    app.CurrentQuestionIndex = 1;
    app.TotalScore = 0;
    app.QuestionsAnswered = 0;
    app.CurrentQuestionScored = false;

    % Display the first question
    app.VivaQuestionTextArea.Value = ...
        {app.VivaQuestions{1}};

    app.VivaAnswerTextArea.Value = {''};

    app.ScoreValueLabel.Text = 'Score:';
    app.Label.Text = '0 / 50';

    app.VivaFeedbackLabel.Text = ...
        'Question 1 of 5. Enter your answer.';








        end

        % Button pushed function: SubmitAnswerButton
        function SubmitAnswerButtonPushed(app, event)
          


    question = strjoin(string(app.VivaQuestionTextArea.Value), ' ');
    answer = lower(strjoin(string(app.VivaAnswerTextArea.Value), ' '));

    if isempty(strtrim(answer))
        uialert(app.UIFigure, ...
            'Please enter your answer.', 'Empty Answer');
        return;
    end

    if app.CurrentQuestionScored
        uialert(app.UIFigure, ...
            'This question has already been evaluated. Click Next Question.', ...
            'Already Evaluated');
        return;
    end

    switch question

        % Digital Signal Processing
        case 'What is DSP?'
            keywords = {'digital','signal','processing'};
        case 'What is the difference between FIR and IIR filters?'
            keywords = {'finite','infinite','impulse'};
        case 'What is FFT?'
            keywords = {'fast','fourier','transform'};
        case 'What is aliasing?'
            keywords = {'sampling','frequency'};
        case 'What is the Nyquist sampling theorem?'
            keywords = {'twice','maximum','frequency'};
        case 'What is spectral leakage?'
            keywords = {'frequency','spectrum','window'};
        case 'What is convolution?'
            keywords = {'input','impulse','response'};
        case 'What is correlation?'
            keywords = {'similarity','signals'};
        case 'What is a window function?'
            keywords = {'signal','frequency','domain'};
        case 'What is a stable system?'
            keywords = {'bounded','input','output'};

        % Digital Communication
        case 'What is digital communication?'
            keywords = {'digital','transmission','information'};
        case 'What is ASK modulation?'
            keywords = {'amplitude','carrier'};
        case 'What is FSK modulation?'
            keywords = {'frequency','carrier'};
        case 'What is PSK modulation?'
            keywords = {'phase','carrier'};
        case 'What is DPSK?'
            keywords = {'differential','phase'};
        case 'What is a Gold sequence?'
            keywords = {'pseudo','random','sequence'};
        case 'What is sampling?'
            keywords = {'continuous','discrete','samples'};
        case 'What is quantization?'
            keywords = {'amplitude','levels'};
        case 'What is PCM?'
            keywords = {'pulse','code','modulation'};
        case 'What is bandwidth?'
            keywords = {'frequency','range'};

        % Signals and Systems
        case 'What is a continuous-time signal?'
            keywords = {'every','time','continuous'};
        case 'What is a discrete-time signal?'
            keywords = {'discrete','samples','instants'};
        case 'What is an even signal?'
            keywords = {'symmetric','time'};
        case 'What is an odd signal?'
            keywords = {'antisymmetric','time'};
        case 'What is a periodic signal?'
            keywords = {'period','repeats'};
        case 'What is the Fourier transform?'
            keywords = {'frequency','domain','time'};
        case 'What is the Laplace transform?'
            keywords = {'complex','frequency','domain'};
        case 'What is a causal system?'
            keywords = {'present','past','future'};
        case 'What is a linear system?'
            keywords = {'superposition','additivity','homogeneity'};
        case 'What is time invariance?'
            keywords = {'time','shift','unchanged'};

        % Electronic Circuits
        case 'What is a diode?'
            keywords = {'current','direction','semiconductor'};
        case 'What is a transistor?'
            keywords = {'amplification','switching','semiconductor'};
        case 'What is an amplifier?'
            keywords = {'signal','amplitude','increase'};
        case 'What is the operating point?'
            keywords = {'dc','bias','quiescent'};
        case 'What is a common emitter amplifier?'
            keywords = {'emitter','voltage','amplification'};
        case 'What is feedback?'
            keywords = {'output','input','signal'};
        case 'What is an oscillator?'
            keywords = {'periodic','signal','frequency'};
        case 'What is a MOSFET?'
            keywords = {'metal','oxide','semiconductor'};
        case 'What is a rectifier?'
            keywords = {'ac','dc','conversion'};
        case 'What is the difference between BJT and FET?'
            keywords = {'current','voltage','controlled'};

        % Control Systems
        case 'What is a control system?'
            keywords = {'control','output','input'};
        case 'What is an open-loop system?'
            keywords = {'feedback','without'};
        case 'What is a closed-loop system?'
            keywords = {'feedback','output'};
        case 'What is transfer function?'
            keywords = {'output','input','laplace'};
        
        case 'What is stability?'
            keywords = {'bounded','output','input'};
        case 'What is damping ratio?'
            keywords = {'damping','oscillation','response'};
        case 'What is natural frequency?'
            keywords = {'frequency','oscillation','undamped'};
        case 'What is a block diagram?'
            keywords = {'blocks','system','signals'};
        case 'What is a signal flow graph?'
            keywords = {'nodes','branches','signals'};

        % Digital Electronics
        case 'What is a logic gate?'
            keywords = {'boolean','operation','input'};
        case 'What is a flip-flop?'
            keywords = {'memory','bit','state'};
        case 'What is a multiplexer?'
            keywords = {'select','input','output'};
        case 'What is a demultiplexer?'
            keywords = {'input','output','select'};
        case 'What is a counter?'
            keywords = {'count','clock','flip'};
        case 'What is a shift register?'
            keywords = {'data','clock','shift'};
        case 'What is a decoder?'
            keywords = {'binary','input','output'};
        case 'What is a Boolean expression?'
            keywords = {'boolean','logic','variables'};
        case 'What is a Mealy machine?'
            keywords = {'output','input','state'};
        case 'What is a Moore machine?'
            keywords = {'output','state'};

        otherwise
            uialert(app.UIFigure, ...
                'Evaluation is not available for this question.', ...
                'Evaluation');
            return;
    end

    matched = 0;

    for k = 1:length(keywords)
        if contains(answer, keywords{k})
            matched = matched + 1;
        end
    end

    score = round((matched / length(keywords)) * 10);

    % Update cumulative score
    app.TotalScore = app.TotalScore + score;
    app.QuestionsAnswered = app.QuestionsAnswered + 1;
    app.CurrentQuestionScored = true;

    app.ScoreValueLabel.Text = 'Score:';
    app.Label.Text = sprintf('%d / 50', app.TotalScore);

    app.VivaFeedbackLabel.Text = sprintf( ...
        'You scored %d / 10. Total: %d / 50.', ...
        score, app.TotalScore);

    uialert(app.UIFigure, ...
        sprintf('Question Score: %d / 10\nCumulative Score: %d / 50', ...
        score, app.TotalScore), ...
        'Viva Result');





   
    



        end

        % Button pushed function: NextQuestionButton
        function NextQuestionButtonPushed(app, event)
        

    % Check whether questions are generated
    if isempty(app.VivaQuestions)
        uialert(app.UIFigure, ...
            'Please generate questions first.', ...
            'No Questions');
        return;
    end

    % Check whether the current answer is submitted
    if ~app.CurrentQuestionScored
        uialert(app.UIFigure, ...
            'Please submit your answer before moving to the next question.', ...
            'Answer Required');
        return;
    end

    % Check whether all five questions are completed
    if app.CurrentQuestionIndex >= length(app.VivaQuestions)

        percentage = (app.TotalScore / 50) * 100;

        app.VivaQuestionTextArea.Value = ...
            {'Viva session completed!'};

        app.VivaAnswerTextArea.Value = {''};

        app.VivaFeedbackLabel.Text = ...
            'You have completed all five questions.';

        uialert(app.UIFigure, ...
            sprintf('Final Score: %d / 50\nPercentage: %.1f%%', ...
            app.TotalScore, percentage), ...
            'Viva Completed');

        return;
    end

    % Move to the next question
    app.CurrentQuestionIndex = app.CurrentQuestionIndex + 1;

    app.VivaQuestionTextArea.Value = ...
        {app.VivaQuestions{app.CurrentQuestionIndex}};

    app.VivaAnswerTextArea.Value = {''};

    app.CurrentQuestionScored = false;

    app.VivaFeedbackLabel.Text = ...
        sprintf('Question %d of 5. Enter your answer.', ...
        app.CurrentQuestionIndex);




    

        
   



        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.9608 0.9686 0.9882];
            app.UIFigure.Position = [100 100 1000 650];
            app.UIFigure.Name = 'MATLAB App';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 1000 650];

            % Create ECETutorTab
            app.ECETutorTab = uitab(app.TabGroup);
            app.ECETutorTab.Title = 'ECE Tutor';
            app.ECETutorTab.BackgroundColor = [0.9412 0.9412 0.9412];
            app.ECETutorTab.ForegroundColor = [0.149 0.149 0.149];

            % Create TitleLabel
            app.TitleLabel = uilabel(app.ECETutorTab);
            app.TitleLabel.FontName = 'Times New Roman';
            app.TitleLabel.FontSize = 24;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontColor = [0 0 0];
            app.TitleLabel.Position = [10 584 402 32];
            app.TitleLabel.Text = 'ECE LabMate - your electronics tutor';

            % Create selectlanguageDropDownLabel
            app.selectlanguageDropDownLabel = uilabel(app.ECETutorTab);
            app.selectlanguageDropDownLabel.BackgroundColor = [1 1 1];
            app.selectlanguageDropDownLabel.HorizontalAlignment = 'right';
            app.selectlanguageDropDownLabel.FontName = 'Times New Roman';
            app.selectlanguageDropDownLabel.FontSize = 18;
            app.selectlanguageDropDownLabel.FontWeight = 'bold';
            app.selectlanguageDropDownLabel.FontColor = [0.149 0.149 0.149];
            app.selectlanguageDropDownLabel.Position = [62 520 120 24];
            app.selectlanguageDropDownLabel.Text = 'select language';

            % Create LanguageDropDown
            app.LanguageDropDown = uidropdown(app.ECETutorTab);
            app.LanguageDropDown.Items = {'english', 'hindi', 'telugu', 'tamil', ''};
            app.LanguageDropDown.FontName = 'Times New Roman';
            app.LanguageDropDown.FontSize = 18;
            app.LanguageDropDown.FontWeight = 'bold';
            app.LanguageDropDown.BackgroundColor = [0.902 0.902 0.902];
            app.LanguageDropDown.Position = [197 520 196 24];
            app.LanguageDropDown.Value = 'english';

            % Create TypeyourelectronicsquestionhereTextAreaLabel
            app.TypeyourelectronicsquestionhereTextAreaLabel = uilabel(app.ECETutorTab);
            app.TypeyourelectronicsquestionhereTextAreaLabel.HorizontalAlignment = 'right';
            app.TypeyourelectronicsquestionhereTextAreaLabel.FontName = 'Times New Roman';
            app.TypeyourelectronicsquestionhereTextAreaLabel.FontSize = 18;
            app.TypeyourelectronicsquestionhereTextAreaLabel.FontWeight = 'bold';
            app.TypeyourelectronicsquestionhereTextAreaLabel.Position = [14 478 264 32];
            app.TypeyourelectronicsquestionhereTextAreaLabel.Text = 'Type your electronics question here...';

            % Create QuestionTextArea
            app.QuestionTextArea = uitextarea(app.ECETutorTab);
            app.QuestionTextArea.FontSize = 18;
            app.QuestionTextArea.FontWeight = 'bold';
            app.QuestionTextArea.Position = [20 391 954 77];

            % Create AskQuestionButton
            app.AskQuestionButton = uibutton(app.ECETutorTab, 'push');
            app.AskQuestionButton.ButtonPushedFcn = createCallbackFcn(app, @AskQuestionButtonPushed, true);
            app.AskQuestionButton.BackgroundColor = [0.149 0.549 0.8667];
            app.AskQuestionButton.FontColor = [1 1 1];
            app.AskQuestionButton.Position = [205 346 100 22];
            app.AskQuestionButton.Text = 'Ask Question';

            % Create AnswerLabel
            app.AnswerLabel = uilabel(app.ECETutorTab);
            app.AnswerLabel.FontName = 'Times New Roman';
            app.AnswerLabel.FontSize = 18;
            app.AnswerLabel.FontWeight = 'bold';
            app.AnswerLabel.Position = [383 312 123 24];
            app.AnswerLabel.Text = 'Tutor''s Answer';

            % Create YouranswerwillappearhereTextAreaLabel
            app.YouranswerwillappearhereTextAreaLabel = uilabel(app.ECETutorTab);
            app.YouranswerwillappearhereTextAreaLabel.HorizontalAlignment = 'right';
            app.YouranswerwillappearhereTextAreaLabel.FontName = 'Times New Roman';
            app.YouranswerwillappearhereTextAreaLabel.FontSize = 18;
            app.YouranswerwillappearhereTextAreaLabel.FontWeight = 'bold';
            app.YouranswerwillappearhereTextAreaLabel.Position = [14 281 246 24];
            app.YouranswerwillappearhereTextAreaLabel.Text = 'Your answer will appear here...';

            % Create AnswerTextArea
            app.AnswerTextArea = uitextarea(app.ECETutorTab);
            app.AnswerTextArea.FontSize = 18;
            app.AnswerTextArea.Position = [14 85 970 188];

            % Create SpeakAnswerButton
            app.SpeakAnswerButton = uibutton(app.ECETutorTab, 'push');
            app.SpeakAnswerButton.ButtonPushedFcn = createCallbackFcn(app, @SpeakAnswerButtonPushed, true);
            app.SpeakAnswerButton.BackgroundColor = [0.149 0.549 0.8667];
            app.SpeakAnswerButton.FontColor = [1 1 1];
            app.SpeakAnswerButton.Position = [214 38 100 22];
            app.SpeakAnswerButton.Text = 'Speak Answer';

            % Create VirtualLabTab
            app.VirtualLabTab = uitab(app.TabGroup);
            app.VirtualLabTab.Title = 'Virtual Lab';
            app.VirtualLabTab.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create UIAxes
            app.UIAxes = uiaxes(app.VirtualLabTab);
            title(app.UIAxes, 'Input Signal')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontName = 'Times New Roman';
            app.UIAxes.FontWeight = 'bold';
            app.UIAxes.FontSize = 18;
            app.UIAxes.Position = [14 281 492 263];

            % Create OutputAxes
            app.OutputAxes = uiaxes(app.VirtualLabTab);
            title(app.OutputAxes, 'Output Signal')
            xlabel(app.OutputAxes, 'X')
            ylabel(app.OutputAxes, 'Y')
            zlabel(app.OutputAxes, 'Z')
            app.OutputAxes.FontName = 'Times New Roman';
            app.OutputAxes.FontWeight = 'bold';
            app.OutputAxes.FontSize = 18;
            app.OutputAxes.Position = [1 21 505 247];

            % Create ExperimentDropDownLabel
            app.ExperimentDropDownLabel = uilabel(app.VirtualLabTab);
            app.ExperimentDropDownLabel.HorizontalAlignment = 'right';
            app.ExperimentDropDownLabel.FontName = 'Times New Roman';
            app.ExperimentDropDownLabel.FontSize = 18;
            app.ExperimentDropDownLabel.FontWeight = 'bold';
            app.ExperimentDropDownLabel.Position = [39 588 181 24];
            app.ExperimentDropDownLabel.Text = 'ExperimentDropDown';

            % Create ExperimentDropDown
            app.ExperimentDropDown = uidropdown(app.VirtualLabTab);
            app.ExperimentDropDown.Items = {'Amplitude Modulation (AM)', 'Frequency Modulation (FM)', 'Half Wave Rectifier', 'Full Wave Rectifier'};
            app.ExperimentDropDown.ValueChangedFcn = createCallbackFcn(app, @ExperimentDropDownValueChanged, true);
            app.ExperimentDropDown.FontName = 'Times New Roman';
            app.ExperimentDropDown.FontSize = 18;
            app.ExperimentDropDown.FontWeight = 'bold';
            app.ExperimentDropDown.BackgroundColor = [0.8 0.8 0.8];
            app.ExperimentDropDown.Position = [237 588 257 24];
            app.ExperimentDropDown.Value = 'Amplitude Modulation (AM)';

            % Create GenerateButton
            app.GenerateButton = uibutton(app.VirtualLabTab, 'push');
            app.GenerateButton.ButtonPushedFcn = createCallbackFcn(app, @GenerateButtonPushed, true);
            app.GenerateButton.BackgroundColor = [0.149 0.549 0.8667];
            app.GenerateButton.FontName = 'Times New Roman';
            app.GenerateButton.FontSize = 18;
            app.GenerateButton.FontColor = [1 1 1];
            app.GenerateButton.Position = [197 546 159 30];
            app.GenerateButton.Text = 'Generate Waveform';

            % Create TheoryTitleLabel
            app.TheoryTitleLabel = uilabel(app.VirtualLabTab);
            app.TheoryTitleLabel.FontName = 'Times New Roman';
            app.TheoryTitleLabel.FontSize = 18;
            app.TheoryTitleLabel.FontWeight = 'bold';
            app.TheoryTitleLabel.FontColor = [0.1216 0.1608 0.2314];
            app.TheoryTitleLabel.Position = [685 566 141 24];
            app.TheoryTitleLabel.Text = 'TheoryTitleLabel';

            % Create TheoryTextAreaLabel
            app.TheoryTextAreaLabel = uilabel(app.VirtualLabTab);
            app.TheoryTextAreaLabel.HorizontalAlignment = 'right';
            app.TheoryTextAreaLabel.FontName = 'Times New Roman';
            app.TheoryTextAreaLabel.FontSize = 18;
            app.TheoryTextAreaLabel.FontWeight = 'bold';
            app.TheoryTextAreaLabel.Position = [544 538 132 24];
            app.TheoryTextAreaLabel.Text = 'TheoryTextArea';

            % Create TheoryTextArea
            app.TheoryTextArea = uitextarea(app.VirtualLabTab);
            app.TheoryTextArea.Editable = 'off';
            app.TheoryTextArea.FontName = 'Times New Roman';
            app.TheoryTextArea.FontSize = 18;
            app.TheoryTextArea.FontWeight = 'bold';
            app.TheoryTextArea.Position = [544 38 430 483];
            app.TheoryTextArea.Value = {'Select an experiment to view its theory.'};

            % Create VivaPracticeTab
            app.VivaPracticeTab = uitab(app.TabGroup);
            app.VivaPracticeTab.Title = 'Viva Practice';

            % Create ECELabMateVivaPracticeLabel
            app.ECELabMateVivaPracticeLabel = uilabel(app.VivaPracticeTab);
            app.ECELabMateVivaPracticeLabel.FontName = 'Times New Roman';
            app.ECELabMateVivaPracticeLabel.FontSize = 24;
            app.ECELabMateVivaPracticeLabel.FontWeight = 'bold';
            app.ECELabMateVivaPracticeLabel.Position = [81 580 382 32];
            app.ECELabMateVivaPracticeLabel.Text = {'ECE LabMate - Viva Practice'; ''};

            % Create SubjectDropDownLabel
            app.SubjectDropDownLabel = uilabel(app.VivaPracticeTab);
            app.SubjectDropDownLabel.HorizontalAlignment = 'right';
            app.SubjectDropDownLabel.FontName = 'Times New Roman';
            app.SubjectDropDownLabel.FontSize = 18;
            app.SubjectDropDownLabel.FontWeight = 'bold';
            app.SubjectDropDownLabel.Position = [-42 546 245 24];
            app.SubjectDropDownLabel.Text = 'SubjectDropDown';

            % Create SubjectDropDown
            app.SubjectDropDown = uidropdown(app.VivaPracticeTab);
            app.SubjectDropDown.Items = {'Digital Signal Processing', 'Electronic Circuits', 'Control Systems', 'Digital Communication', 'Signals and Systems', 'Digital Electronics'};
            app.SubjectDropDown.FontName = 'Times New Roman';
            app.SubjectDropDown.FontSize = 18;
            app.SubjectDropDown.FontWeight = 'bold';
            app.SubjectDropDown.Position = [226 543 268 24];
            app.SubjectDropDown.Value = 'Digital Signal Processing';

            % Create GenerateQuestionsButton
            app.GenerateQuestionsButton = uibutton(app.VivaPracticeTab, 'push');
            app.GenerateQuestionsButton.ButtonPushedFcn = createCallbackFcn(app, @GenerateQuestionsButtonPushed, true);
            app.GenerateQuestionsButton.BackgroundColor = [0.149 0.549 0.8667];
            app.GenerateQuestionsButton.FontName = 'Times New Roman';
            app.GenerateQuestionsButton.FontSize = 18;
            app.GenerateQuestionsButton.FontColor = [1 1 1];
            app.GenerateQuestionsButton.Position = [132 491 277 30];
            app.GenerateQuestionsButton.Text = 'Generate Questions';

            % Create VivaQuestionTextAreaLabel
            app.VivaQuestionTextAreaLabel = uilabel(app.VivaPracticeTab);
            app.VivaQuestionTextAreaLabel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.VivaQuestionTextAreaLabel.HorizontalAlignment = 'right';
            app.VivaQuestionTextAreaLabel.FontName = 'Times New Roman';
            app.VivaQuestionTextAreaLabel.FontSize = 18;
            app.VivaQuestionTextAreaLabel.FontWeight = 'bold';
            app.VivaQuestionTextAreaLabel.FontColor = [0 0 0];
            app.VivaQuestionTextAreaLabel.Position = [8 426 190 32];
            app.VivaQuestionTextAreaLabel.Text = 'VivaQuestionTextArea';

            % Create VivaQuestionTextArea
            app.VivaQuestionTextArea = uitextarea(app.VivaPracticeTab);
            app.VivaQuestionTextArea.FontColor = [0.149 0.149 0.149];
            app.VivaQuestionTextArea.Position = [205 378 748 80];

            % Create VivaAnswerTextAreaLabel
            app.VivaAnswerTextAreaLabel = uilabel(app.VivaPracticeTab);
            app.VivaAnswerTextAreaLabel.HorizontalAlignment = 'right';
            app.VivaAnswerTextAreaLabel.FontName = 'Times New Roman';
            app.VivaAnswerTextAreaLabel.FontSize = 18;
            app.VivaAnswerTextAreaLabel.FontWeight = 'bold';
            app.VivaAnswerTextAreaLabel.Position = [364 335 169 24];
            app.VivaAnswerTextAreaLabel.Text = 'VivaAnswerTextArea';

            % Create VivaAnswerTextArea
            app.VivaAnswerTextArea = uitextarea(app.VivaPracticeTab);
            app.VivaAnswerTextArea.Position = [43 170 931 162];

            % Create SubmitAnswerButton
            app.SubmitAnswerButton = uibutton(app.VivaPracticeTab, 'push');
            app.SubmitAnswerButton.ButtonPushedFcn = createCallbackFcn(app, @SubmitAnswerButtonPushed, true);
            app.SubmitAnswerButton.BackgroundColor = [0.149 0.549 0.8667];
            app.SubmitAnswerButton.FontName = 'Times New Roman';
            app.SubmitAnswerButton.FontSize = 18;
            app.SubmitAnswerButton.FontColor = [1 1 1];
            app.SubmitAnswerButton.Position = [169 129 196 30];
            app.SubmitAnswerButton.Text = 'SubmitAnswerButton';

            % Create VivaFeedbackLabel
            app.VivaFeedbackLabel = uilabel(app.VivaPracticeTab);
            app.VivaFeedbackLabel.FontName = 'Times New Roman';
            app.VivaFeedbackLabel.FontSize = 18;
            app.VivaFeedbackLabel.FontWeight = 'bold';
            app.VivaFeedbackLabel.Position = [268 73 439 24];
            app.VivaFeedbackLabel.Text = 'VivaFeedbackLabel';

            % Create NextQuestionButton
            app.NextQuestionButton = uibutton(app.VivaPracticeTab, 'push');
            app.NextQuestionButton.ButtonPushedFcn = createCallbackFcn(app, @NextQuestionButtonPushed, true);
            app.NextQuestionButton.BackgroundColor = [0.149 0.549 0.8667];
            app.NextQuestionButton.FontName = 'Times New Roman';
            app.NextQuestionButton.FontSize = 18;
            app.NextQuestionButton.FontColor = [1 1 1];
            app.NextQuestionButton.Position = [706 116 172 30];
            app.NextQuestionButton.Text = 'NextQuestionButton';

            % Create ScoreValueLabel
            app.ScoreValueLabel = uilabel(app.VivaPracticeTab);
            app.ScoreValueLabel.FontName = 'Times New Roman';
            app.ScoreValueLabel.FontSize = 18;
            app.ScoreValueLabel.FontWeight = 'bold';
            app.ScoreValueLabel.Position = [277 21 232 24];
            app.ScoreValueLabel.Text = 'ScoreValueLabel';

            % Create Label
            app.Label = uilabel(app.VivaPracticeTab);
            app.Label.FontName = 'Times New Roman';
            app.Label.FontSize = 18;
            app.Label.FontWeight = 'bold';
            app.Label.Position = [462 21 208 24];
            app.Label.Text = '0 / 10';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ECELabMate_New_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end