// SLC syntax definition
module.exports = {
    name: 'slc',
    case_insensitive: true,
    keywords: {
        keyword: 'data proc run',
        built_in: '_null_ print'
    },
    contains: [
        {
            className: 'string',
            begin: '"',
            end: '"'
        },
        {
            className: 'comment',
            begin: '/\\*',
            end: '\\*/',
            contains: ['self']
        },
        {
            className: 'comment',
            begin: ';',
            end: '$'
        }
    ]
}