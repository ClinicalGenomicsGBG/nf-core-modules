
process SENTIEON_DNASCOPE {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::sentieon=202112.01" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sentieon:202112.01--h5b5514e_0':
        'quay.io/biocontainers/sentieon:202112.01--h5b5514e_0' }"

    input:
    tuple val(meta), path(bam), path(bai)
    path fasta
    path fai
    path dbsnp
    path dbsnp_index
    path ml_model
    val pcrfree

    output:
    tuple val(meta), path("*.vcf"), path("*.vcf.idx"), emit: tmp_vcf
    path "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def call_settings = pcrfree ? "--pcr_indel_model NONE" : ''
    def dbSNP = dbsnp ? "-d ${dbsnp}" : ''
    def ML_MDL = ml_model ? "--model ${ml_model}" : ''

    """
    sentieon driver \\
        -t ${task.cpus} \\
        -r ${fasta} \\
        ${args2} \\
        -i ${bam} \\
        --algo DNAscope \\
        ${dbSNP} \\
        ${args} \\
        ${call_settings} \\
        ${ML_MDL} \\
        ${prefix}_dnascope_tmp.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sentieon: \$(echo \$(sentieon driver --version 2>&1) | sed 's/^.*sentieon //; s/Using.*\$//' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.vcf
    touch ${prefix}.vcf.idx
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sentieon: \$(echo \$(sentieon driver --version 2>&1) | sed 's/^.*sentieon //; s/Using.*\$//' )
    END_VERSIONS
    """
}
