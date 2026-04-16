stats_table = mil310_change_detection(data, "t2m", ...
    window1=[1950 1980], ...
    window2=[1995 2025]);

generate_full_era5_report(results_all, stats_table, "Era5/Postprocess");

function generate_full_era5_report(results_all, stats_table, output_dir)

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

tex_file = fullfile(output_dir, "ERA5_FULL_REPORT.tex");
fid = fopen(tex_file, 'w');

if fid == -1
    error("Cannot create LaTeX file.");
end

% ==========================================================
% HEADER
% ==========================================================
fprintf(fid, "\\documentclass{article}\n");
fprintf(fid, "\\usepackage{booktabs}\n");
fprintf(fid, "\\usepackage{graphicx}\n");
fprintf(fid, "\\usepackage{geometry}\n");
fprintf(fid, "\\geometry{margin=1in}\n");
fprintf(fid, "\\title{ERA5 MIL-310 Climate Analysis Report}\n");
fprintf(fid, "\\begin{document}\n");
fprintf(fid, "\\maketitle\n");

fprintf(fid, "\\section{Overview}\n");
fprintf(fid, "This report combines MIL-310 exceedance statistics with change detection analysis using KS and rank-sum tests.\\\\\n");

% ==========================================================
% CITY RESULTS
% ==========================================================
fprintf(fid, "\\section{City-Level Results}\n");

for i = 1:length(results_all)

    city = string(results_all(i).city);

    % escape LaTeX special characters
    city_tex = strrep(city, "_", "\\_");

    city_path = fullfile("Era5/Postprocess", city);

    fprintf(fid, "\\subsection{%s}\n", city_tex);

    % -----------------------------
    % Tables (FIXED PATHS)
    % -----------------------------
    fprintf(fid, "\\subsubsection{Annual MIL-310 Statistics}\n");
    fprintf(fid, "\\pgfplotstabletypeset[col sep=comma]{%s/MIL310_summary_%s_year.csv}\n", ...
        city_path, city);

    fprintf(fid, "\\subsubsection{Hourly Statistics}\n");
    fprintf(fid, "\\pgfplotstabletypeset[col sep=comma]{%s/MIL310_summary_%s_month_1hr.csv}\n", ...
        city_path, city);

    fprintf(fid, "\\subsubsection{24h Statistics}\n");
    fprintf(fid, "\\pgfplotstabletypeset[col sep=comma]{%s/MIL310_summary_%s_month_24hr.csv}\n", ...
        city_path, city);

    % -----------------------------
    % FIGURE
    % -----------------------------
    fig_path = fullfile(city_path, "kernel_density_full.png");

    fprintf(fid, "\\begin{figure}[h!]\n");
    fprintf(fid, "\\centering\n");
    fprintf(fid, "\\includegraphics[width=0.75\\textwidth]{%s}\n", fig_path);
    fprintf(fid, "\\caption{Kernel Density of t2m for %s}\n", city_tex);
    fprintf(fid, "\\end{figure}\n");

end

% ==========================================================
% CHANGE DETECTION SECTION
% ==========================================================
fprintf(fid, "\\section{Change Detection Analysis}\n");

fprintf(fid, "\\begin{tabular}{c c c c}\n");
fprintf(fid, "\\toprule\n");
fprintf(fid, "Month & KS p-value & KS Sig & Classification \\\\\n");
fprintf(fid, "\\midrule\n");

for i = 1:height(stats_table)

    ks_p = stats_table.KS_p(i);
    ks_sig = stats_table.KS_sig(i);

    tail_vals = stats_table{i, 4:end};
    tail_vals = tail_vals(~isnan(tail_vals));

    is_tail_sig = any(tail_vals < 0.05);

    if ks_p < 0.05 && is_tail_sig
        label = "Strong Shift (Full + Tail)";
    elseif ks_p < 0.05
        label = "Distribution Shift";
    elseif is_tail_sig
        label = "Tail Shift Only";
    else
        label = "No Change";
    end

    fprintf(fid, "%d & %.3g & %d & %s \\\\\n", ...
        stats_table.Month(i), ks_p, ks_sig, label);

end

fprintf(fid, "\\bottomrule\n");
fprintf(fid, "\\end{tabular}\n");

% ==========================================================
% FOOTER
% ==========================================================
fprintf(fid, "\\section{Interpretation}\n");
fprintf(fid, "KS test captures full distribution changes while rank-sum tests isolate extreme tail behavior relevant for exceedance events.\\\\\n");

fprintf(fid, "\\end{document}\n");

fclose(fid);

fprintf("LaTeX report written: %s\n", tex_file);

% ==========================================================
% COMPILE PDF
% ==========================================================
system(sprintf('pdflatex -output-directory="%s" "%s"', output_dir, tex_file));

end