pragma solidity ^0.4.24;

/**
 * @dev Математические операции, с проверками безопасности
 */
library SafeMath {

    /**
        @dev Операция безопасного умножения
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        // Вызывает исключение, если C делённое на A не равно B,
        // там ещё проверка деления на ноль сразу же
        assert(a == 0 || c / a == b);
        return c;
    }

    /**
        @dev Операция безопасного деления
     */
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // В новой версии это исключение вызывается автоматом
        uint c = a / b;
        // assert(a == b * c + a % b); // Нет случаев, когда это исключение выполнится
        return c;
    }

    /**
        @dev Операция безопасного вычитания
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        // У нас доступны только положительные целые числа, значит А должно быть больше B. 
        // 0, судя по всему тоже возвращать нельзя.
        assert(b <= a);
        return a - b;
    }

    /**
        @dev Операция безопасного сложения
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        //Короче говоря, проверка того, что B не был отрицательным О_о.
        assert(c >= a);
        return c;
    }

    /**
        @dev Операция безопасной проверки какое число больше (64 бита)
     */
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    /**
        @dev Операция безопасной проверки какое число меньше (64 бита)
     */
    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /**
        @dev Операция безопасной проверки какое число больше  (256 бит)
     */
    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
        @dev Операция безопасной проверки какое число больше (256 бит)
     */
    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
    @dev Контракт, устанавливающий владельца другого контракта
    плюс, имеющий внутри модификатор запуска, для защиты от
    запуска других функций не владельцем 
 */
contract Ownable {

    //Адрес владельца контракта
    address private owner;

    /**
        @dev модификатор, позволяющий запускать функции 
        только владельцу контракта
     */
    modifier onlyOwner() {
        //Проверка того, что запускающий является владельцем
        require(msg.sender == owner);
        //Вызов основной функции
        _;
    }

    /**
        @dev Конструктор контракта. При инициализации контракта,
        прописывает создателя, как владельца.  
     */
    constructor() public {
        //Запоминаем создателя
        owner = msg.sender;
    }

    /**
        @dev функция передачи права владения контрактом другому 
        пользователю. Может быть вызвана только владельцем.
        @param newOwner - адрес нового владельца
     */
    function transferOwnership (address newOwner) public onlyOwner {
        //Если переданный адрес существует
        if(newOwner != address(0)) {
            //Меняем владельца
            owner = newOwner;
        }
    }

    /**
        @dev Проверка того, что _sender - это владелец
        @param _sender - проверяемый человек
     */
    function isOwner(address _sender) internal view returns(bool) {
        return (_sender == owner);
    }
}

/**
    @dev Контракт, устанавливающий адрес человека, которому 
    разрешено подписывать транзакции. Содержит в себе 
    модификатор, разрешающий вызов функции только для  
    подписывателя транзакций.
 */
contract Signatory is Ownable {

    //Адрес подписывателя
    address private signer;

    /**
        @dev модификатор, позволяющий вызов функции только
        для подписывателя транзакций.
     */
    modifier onlySigner() {
        require(msg.sender == signer);
        _;
    }

    /**
        @dev Конструктор контракта. При инициализации контракта,
        прописывает нулевой адрес, как адрес подписывателя
     */
    constructor() public {
        signer = address(0);
    }

    /**
        @dev Функция, позволяющая прописывать нового подписывателя
        транзакций владельцу контракта.
        @param newSigner - новый адрес подписывателя
     */
    function setSigner(address newSigner) public onlyOwner {
          //Если переданный адрес существует
        if(newSigner != address(0)) {
            //Меняем подписывателя
            signer = newSigner;
        }
    }

    /**
        @dev Проверка того, что _sender - это подписыватель
        @param _sender - проверяемый человек
     */
    function isSigner(address _sender) internal view returns(bool) {
        return (_sender == signer);
    }
}

/**
    @dev Библиотека, реализующая хренение адресов команды
    для того, чтобы перевести на них токены по старту
    и заблокировать их на 6 месяцев
 */
contract Team is Ownable {
    //Адреса кошельков команды, для проверки - является
    //ли указанный кошель командным
    mapping(address => uint) private teamAccounts;
    //Адреса кошельков команды, в виде массива, для 
    //перевода на них средств
    address[] private teamAccountsArray;
    //Количество заполненных кошельков команды 
    uint private teamSetCount;
    //Флаг разрешающий переводы, для команды 
    bool private allowTeamTransfer;


    /**
        @dev Конструктор контракта. При инициализации контракта,
        прописывает нулевой адрес, как адрес подписывателя
     */
    constructor() public {
        //Инициализируем массив адресов на 10 позиций
        teamAccountsArray = new address[] (10);
        //Запрещаем переводы токенов, с командных счетов
        allowTeamTransfer = false;
        //Инициализируем количество командных кошельков
        teamSetCount = 0;
    }

    /**
        @dev Функция, позволяющая добавлять нового члена команды
        @param newAccount - адрес нового кошелька
     */
    function addTeamAccount(address newAccount) public onlyOwner {
        //Если переданный адрес существует, не находится в нашем списке
        //и количество членов команды меньше 10
        if((newAccount != address(0)) && !isTeam(newAccount) && (teamSetCount < 10)) {
            //Записываем в общий список кошелёк
            teamAccounts[newAccount] = 31337;
            //Записываем адрес кошелька в массив
            teamAccountsArray[teamSetCount] = newAccount;      
            //Увеличиваем счётчик количества командных аккаунтов
            teamSetCount++;      
        } else {
            //Иначе - вызываем ошибку выполнения
            require(false);
        }
    }

    /**
        @dev проверка того, что указанный аккаунт относится к командным
        @param account - адрес проверяемого кошелька
     */
    function isTeam(address account) internal view returns(bool) {   
        //Если данный кошелёк принаждлежит команде    
        return (teamAccounts[account] == 31337);
    }

    /**
        @dev проверка того, что с данного адреса можно перевести токены
        @param account - адрес проверяемого кошелька
     */
    function isTeamAllow(address account) public view returns(bool) {
        //Если адрес аккаунта есть в списке командных, 
        //то возвращаем инфу о том, можно ли переводить 
        //с командных аккаунтов. В противном случае -
        //просто разрешаем.
        return (isTeam(account)) ? allowTeamTransfer : true;
    }

    /**
        @dev Разрешает проведение переводов, от имени команды
     */
    function allowTeamTransfers() public onlyOwner {
        //Разрешаем переводы токенов, с командных счетов
        allowTeamTransfer = false;
    }

    /**
        @dev Возвращает массив кошельков команды
     */
    function getTeamAccounts() public view returns(address[]) {
        return teamAccountsArray;
    }
}


/**
    @dev Контракт, реализующий возврат токенов.
    Содержит адрес пересылки, при приходе
    токенов на который, они будут возвращены в 
    основные кошельки    
 */
contract RefundTokens is Ownable {
    /**
        @dev Структура, хранящая информацию о возврате
     */
    struct RefundInfo {
        //Сумма возврата
        uint cost;
        //Метка времени возврата
        uint timestamp;        
    }

    //Адрес возврата
    address private refund;    

    //Информация о возврате. Представляет из себя список, в котором
    //Каждому адресу ассоциирован массив элементов, с информацией об 
    //одной операции возврата.
    mapping(address => RefundInfo[]) private refundList;

    /**
        @dev Конструктор контракта. При инициализации контракта,
        прописывает нулевой адрес, как адрес возврата
     */
    constructor() public {
        refund = address(0);
    }


    /**
        @dev Функция, позволяющая прописывать новый адрес возврата.
        @param newRefund - новый адрес возврата
     */
    function setRefund(address newRefund) public onlyOwner {
          //Если переданный адрес существует
        if(newRefund != address(0)) {
            //Меняем подписывателя
            refund = newRefund;
        }
    }

    /**
        @dev проверрка того, что введённый адрес является адресом возврата
        @param _refund - адрес, проверяемый на возврат
     */
    function isRefund(address _refund) internal view returns(bool) {
        //Сравниваем адреса
        return (refund == _refund);
    }

    /**
        @dev Добавляние информации об операции возврата в список
        @param _sender - адрес отправителя транзакции
        @param cost - сумма возврата
     */
    function addRefund(address _sender, uint cost) internal {
        //Инициализируем информацию о возврате
        RefundInfo memory ri;
        ri.cost = cost;
        ri.timestamp = now;
        //Добавляем её в массив возвратов
        refundList[_sender].push(ri);
    }

    /**
        @dev Возвращает список возвратов пользователя
        @param _sender - адрес пользователя, для которого необходимо вернуть инфомрацию
        @return список возвратов
     */
    function getRefunds(address _sender) public view onlyOwner returns(uint[] costs, uint[] timestamps) {
        //Получаем длинну списка транзакций
        uint len = refundList[_sender].length;
        //Инициализируем выходные массивы
        costs = new uint[] (len);
        timestamps = new uint[] (len);
        //Проходимся по трензакциям и сохраняем значения
        for(uint i = 0; i < len; i++) {
            costs[i] = refundList[_sender][i].cost;
            timestamps[i] = refundList[_sender][i].timestamp;
        }        
    }

    /**
        @dev Возвращает список возвратов пользователя
        @param _sender - адрес пользователя, для которого необходимо вернуть инфомрацию
        @return список возвратов
     */
    function getRefundsInfo(address _sender) internal view onlyOwner returns(RefundInfo[]) {
        return refundList[_sender];
    }

    /**
        @dev Очищает список возвратов пользователя
        @param _sender - адрес пользователя, для которого необходимо очистить список
     */
    function clearRefunds(address _sender) internal onlyOwner {
        //Реинициализируем массив информации о возвратах в пустой
        refundList[_sender].length = 0;
    }
}


/**
 * @title ERC20Basic
 * @dev Базовая версия интерфейса ERC20
 */
contract ERC20Basic {
    //Переменная с общим количеством выпущенных токенов
    uint public totalSupply;
    //Функция получения баланса пользователя
    function balanceOf(address who) public returns (uint);
    //Функция отправки токенов пользователю
    function transfer(address to, uint value) public;
    //Событие, которое вызывается при отправке токенов
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 */
contract ERC20 is ERC20Basic {
    //Функция проверки доступа адреса к отправке
    function allowance(address owner, address spender) public returns (uint);
    //Функция передачи чего-то от одного адреса к другому
    function transferFrom(address from, address to, uint value) public;
    //Функция подтверждения доставки
    function approve(address spender, uint value) public;
    //Событие подтверждения доставки
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Базовый токен
 * @dev Базовая версия стандартного токена, без проверок
 */
contract BasicToken is ERC20Basic {
    //Ссылка на контракт безопасной математики
    using SafeMath for uint;
    //Список балансов пользователей
    mapping(address => uint) public balances;

    /**
        @dev Фикс, для атаки короткими адресами, в ERC20.
        Не позволяет запукать функцию, если адрес отправляющего меньше
        Определённого размера + 4.
        @param size - сверяемый размер
    */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    /**
    * @dev Отправка токенов указанному адресу, с фиксом атаки адресами, короче 64 символов.
    * @param _to Адрес, на который отправляем токены.
    * @param _value Сумма, для отправки.
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {     
        //Если на счету отправителя есть необходимая сумма
        if(balances[msg.sender] >= _value) {
            //Снимаем с баланса отправляющего сумму платежа
            balances[msg.sender] = balances[msg.sender].sub(_value);
            //Прибавляем к балансу получателя сумму платежа
            balances[_to] = balances[_to].add(_value);
            //Вызываем событие, уведомляющее об отправке платежа
            emit Transfer(msg.sender, _to, _value);
        } else {
            //В противном случае - вызываем ошибку
            require(false);
        }
    }

    /**
    * @dev Отправка токенов, с обменом на виртуальные токены, с фиксом атаки адресами, короче 64 символов.
    * @param _to Адрес, на который отправляем токены.
    * @param _value Сумма, для отправки.
    */
    function remove(address _to, uint _value) internal onlyPayloadSize(2 * 32) {     
        //Если на счету отправителя есть необходимая сумма
        if(balances[msg.sender] >= _value) {
            //Снимаем с баланса отправляющего сумму платежа
            balances[msg.sender] = balances[msg.sender].sub(_value);
            //Вызываем событие, уведомляющее об отправке платежа
            emit Transfer(msg.sender, _to, _value);
        } else {
            //В противном случае - вызываем ошибку
            require(false);
        }
    }
    /**
    * @dev Получаем баланс, указанного адреса
    * @param _owner Адрес, чей баланс узнаём. 
    * @return Сумма баланса, на указанном адресе.
    */
    function balanceOf(address _owner) public returns (uint balance) {
        return balances[_owner];
    }

    /**
    * @dev проверяем существование стедств, на балансе данного пользователя
    * @param _owner Адрес, чей баланс проверяем. 
    * @return False - если есть средства на счету пользователя
    */
    function isBalance(address _owner) public view returns (bool) {
        return (balances[_owner] == 0);
    }
}

/**
 * @title Токен, созданный по стандарту ERC20
 *
 * @dev Реализация самого обычного токена
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {
    // Короче говоря, эта хрень указывает, для каждого адреса
    // список адресов и сумму токенов, которую второй адрес 
    //может снять от имени первого.
    mapping (address => mapping (address => uint)) private allowed;

    /**
    * @dev Отправка токенов от одного адреса к другому
    * @param _from Адрес, с которого вы хотите отправить токены
    * @param _to address Адрес ,которому вы хотите отправить токены
    * @param _value uint Сумма токенов, которую вы хотите отправить
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {     
        // Получаем сумму токенов, которую вы можете отправить с адреса _from, 
        // от лица адреса отправителя сообщения 
        uint _allowance = allowed[_from][msg.sender];
        //Если на счету, разрешённом к взаимодействию, 
        //есть указанная сумма
        if(_allowance >= _value) {
            // Уменьшаем сумму, которую вы можем снять от лица отправителя с баланса отпарляющего
            allowed[_from][msg.sender] = _allowance.sub(_value);
            // Уменьшаем баланс отправляющего
            balances[_from] = balances[_from].sub(_value);
            // Увеличиваем баланс принимающего
            balances[_to] = balances[_to].add(_value);
            // Вызываем ивент отправки средств
            emit Transfer(_from, _to, _value);
        } else {
            //В противном случае возвращаем ошибку
            require(false);
        }
    }


    /**
    * @dev Отправка токенов от одного адреса в виртуальные токены
    * @param _from Адрес, с которого вы хотите отправить токены
    * @param _to address Адрес ,которому вы хотите отправить токены
    * @param _value uint Сумма токенов, которую вы хотите отправить
    */
    function removeFrom(address _from, address _to, uint _value) internal onlyPayloadSize(3 * 32) {     
        // Получаем сумму токенов, которую вы можете отправить с адреса _from, 
        // от лица адреса отправителя сообщения 
        uint _allowance = allowed[_from][msg.sender];
        //Если на счету, разрешённом к взаимодействию, 
        //есть указанная сумма
        if(_allowance >= _value) {
            // Уменьшаем сумму, которую вы можем снять от лица отправителя с баланса отпарляющего
            allowed[_from][msg.sender] = _allowance.sub(_value);
            // Уменьшаем баланс отправляющего
            balances[_from] = balances[_from].sub(_value);
            // Вызываем ивент отправки средств
            emit Transfer(_from, _to, _value);
        } else {
            //В противном случае возвращаем ошибку
            require(false);
        }
    }

    /**
    * @dev Разрешаем указанному адресу отправлять указанную сумму токенов,
    *  от имени человека вызвавшего функцию.
    * @param _spender Адрес, которому разрешается отправлять средства.
    * @param _value Количество токенов, которое ему разрешено отправить.
    */
    function approve(address _spender, uint _value) public {

        // Чтобы изменить сумму утверждения, вам сначала надо уменьшить допустимое 
        // количество адресов до 0, вызвав `approve(_spender, 0)`, если только оно
        // уже не равно нулю, чтобы смягчить условия гонки, описанной здесь:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) 
            require(false); //Решение кривое, но мне влом щас думать, как переписать это условие на обратное

        // Устанавливаем сумму токенов, которую данный адрес может переслать другому,
        // от лица вызыввшего функцию
        allowed[msg.sender][_spender] = _value;
        // Вызываем ивент, сообщающий об этом
        emit Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Функция, возвращающая количество токенов, которое _spender может отправить
    * от лица _owner. 
    * @param _owner Адрес, от чьего имени будет отправка токенов.
    * @param _spender Адрес, который будет отправлять токены
    * @return Сумма токенов, доступная к отправке
    */
    function allowance(address _owner, address _spender) public returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

/**
    @dev контракт, реализующий один из мини-кошельков, 
    на которых хранятся токены
 */
contract TokensWallet is Ownable {
    //Баланс данного кошелька
    uint private balance;

    /**
        @dev Конструктор инициализирует данный кошелёк, 
        с фиксированной суммой.
     */
    constructor() public {
        //Инициализация кошелька суммой в 5 000 000 токенов
        //добавить 5 нолей, т.к. у нас пять знаков после запятой
        balance = 500000000000;
    }

    /**
        @dev проверяет наличие средств на кошельке
     */
    function isExists() public view returns(bool) {
        return (balance > 0);
    }

    /**
        @dev проверяет, что кошелёк не полон
     */
    function isFull() public view returns(bool) {
        //Если баланс ниже максимума
        //добавить 5 нолей, т.к. у нас пять знаков после запятой
        return (balance < 500000000000);
    }


    /**
        @dev Вкладываем средства в кошель
        @param cost - сумма, которую возвращаем
        @return - часть суммы, на которую не хватило максимальной вместимости кошелька
     */
    function setMoney(uint cost) public onlyOwner returns(uint) {
        //Получаем сумму, которая будет при вкладывании в кошель средств
        uint remainder = balance + cost;
        
        //Если сумма платежа больше вместимости
        if(remainder > 500000000000)
        {
            //Считаем остаток
            remainder -= 500000000000;
            //Ставим баланс на максимум
            balance = 500000000000;
        //В противном случае
        } else {
            //Присваиваем новый баланс 
            balance = remainder;
            //И ставим остаток в 0
            remainder = 0;
        }

        return remainder;
    }

    /**
        @dev снимаем средства с кошелька
        @param cost - сумма, которую снимаем с кошелька
        @return - часть суммы, на которую не хватило баланса кошелька
     */
    function getMoney(uint cost) public onlyOwner returns(uint) {
        uint remainder;
        
        //Если сумма платежа меньше баланса кошелька 
        if(cost <= balance)
        {
            //Устанавливаем остаток в 0
            remainder = 0;
            //Просто снимаем сумму с баланса
            balance -= cost;
        //В противном случае
        } else {
            //Получаем остаток суммы
            remainder = cost - balance;
            //и обнуляем баланс
            balance = 0;
        }

        return remainder;
    }
}


/**
 * @title Mintable token
 * @dev Разширение базового токена
 */
contract MintableToken is StandardToken, Ownable, Signatory, RefundTokens {
    
    /**
        @dev Структура, хранящая информацию о транзакции
     */
    struct Transaction {
        //Адрес получателя токенов
        address _to;
        //Сумма перевода
        uint cost;
        //Подпись, для подтверждения транзакции
        bool sign;
        //Подпись, для создания транзакции
        bool create;
    }
    
    //Общий запас токенов
    uint public totalSupply;    
    //Общее количество кошельков
    uint private walletsCount;  
    //Флаг, разрешающий раздачу токенов команде
    bool private teamFlag;
    //Указываем, сколько токенов пойдёт на один командный кошелёк
    uint private teamWalletTokens;
    //Флаг, показывающий, что работа смартконтракта была запущена
    bool public work;

    //Кошельки, на которых хранится запас уже напечатанных токенов
    TokensWallet[] private wallets;

    //Список транзакций, по переводу токенов из кошельков
    mapping(bytes32 => Transaction) private transactions;

    /**
        @dev Модификатор, запрещающий выполнение функции, 
        до начала работы контракта 
     */
    modifier isWork() {
        require(work);
        _;
    }

    /**
        @dev Модификатор, запрещающий выполнение функции, 
        после начала работы контракта 
     */
    modifier isNotWork() {
        require(!work);
        _;
    }

    /**
        @dev Модификатор, запрещающий выполнение функции, 
        если вызывающий не создатель ИЛИ подписыватель
     */
    modifier isOwnerOrSigner() {
        require(isOwner(msg.sender) || isSigner(msg.sender));
        _;
    }
    /**
        @dev Конструктор контракта, ответственного 
        за количество напечатанных токенов
     */
    constructor() public {
        //Указываем, что смартконтракт ещё не был запущен
        work = false;
        //Указываем, что раздача токенов команде разрешена
        teamFlag = true;
        //Указываем общую сумму токенов, которые 
        //будут участвовать в обороте
        //добавить 5 нолей, т.к. у нас пять знаков после запятой
        totalSupply = 10000000000000;
        //Инициализируем все внутренние кошельки с токенами
        //1 кошелёк - 5млн токенов, значит у нас будет
        //20 отдельных кошельков.
        //Указываем, сколько у нас кошельков
        walletsCount = 20;
        //Инициализируем массив кошельков
        wallets = new TokensWallet[] (walletsCount);
        //Инициализируем кажыдй из них
        for(uint i = 0; i < walletsCount; i++) {
            //Инициализируем кошелёк
            wallets[i] = new TokensWallet();
        }
        //Указываем, сколько токенов пойдёт на один
        //командный адрес. Команде отходит 20% 
        //от общего количества токенов. 
        //Всего командных кошельков - 20. Таком образом,
        //на один командный адрес пойдёт: 
        //(100`000`000 * 0,2) / 20 = 1 000 000 токенов        
        teamWalletTokens = 1000000;
    }    

    /**
        @dev Снимаем указанную сумму, с кошельков
        @param cost - сумма транзакции в токенах
        @return - остаток суммы, в случае, если не останется свободных токенов
     */
    function removeTokens(uint cost) internal isOwnerOrSigner returns(uint) {
        //Указываем всю сумму, как остаток по дефолту
        uint remainder = cost;
        //Выбираемнулевой кошелёк
        uint selectWallet = 0;  

        //Цикл, идущий до тех пор, пока мы не выкачаем из кошельков 
        //нужную сумму, либо, пока у нас не закончатся кошельки
        while((remainder > 0) && (selectWallet < walletsCount)) {
            //Если на проверяемом кошельке есть токены
            if(wallets[selectWallet].isExists()) {
                //Снимаем сумму с кошелька, и получаем неснятую 
                //часть суммы (если на кошельке не хватило средств)
                remainder = wallets[selectWallet].getMoney(remainder);
                //Если мы сняли не всё
                if(remainder > 0) {
                    //Переходим к следующему кошельку
                    selectWallet++;
                }
            } else {
                //Переходим к следующему кошельку
                selectWallet++;
            }
        }

        //Если на кошельках не хватило средств, остаток мы 
        //вернём, в виде возвращаемого значения
        return remainder;
    }

    /**
        @dev Возвращаем токены в кошельки
        @param cost - количество возвращаемых токенов
     */
    function returnTokens(uint cost) internal onlyOwner isWork {
        //Указываем всю сумму, как остаток по дефолту
        uint remainder = cost;
        //Выбираемнулевой кошелёк
        uint selectWallet = 0;  
        
        //Цикл, идущий до тех пор, пока мы не вернём в кошельки 
        //нужную сумму, либо, пока у нас не закончатся кошельки
        //Но это невозможно - количество токенов, курсирующих в 
        //сети равно общей вместимости кошельков. 
        while((remainder > 0) && (selectWallet < walletsCount)) {
            //Если в проверяемом кошельке есть место
            if(!wallets[selectWallet].isFull()) {
                //Запихиваем токены в кошелёк, и получаем количество
                //токенов, которые в него не вместились
                remainder = wallets[selectWallet].setMoney(remainder);
                //Если мы скинули не всё
                if(remainder > 0) {
                    //Переходим к следующему кошельку
                    selectWallet++;
                }
            } else {
                //Переходим к следующему кошельку
                selectWallet++;
            }
        }
    }

    /**
        @dev Раздаём токены команде
        @param teamAccounts - массив аккаунтов, принадлежащих команде
     */
    function setTeamTokens(address[] teamAccounts) internal onlyOwner isNotWork {
        //Если раздача токенов команде разрешена
        if(teamFlag == true) {            
            //Проходимся, по полученному списку аккаунтов
            for (uint i = 0; i < teamAccounts.length; i++) {
                //Отправляем токены на кошелёк
                sentTeamTokens(teamAccounts[i]);
            }
            //Запрещаем дальнейшую раздачу токенов команде
            teamFlag = false;
        } else {
            //В противном случае выдаём ошибку
            require(false);
        }
    }

    /**
        @dev отправляем командные токены
        @param _to - получатель токенов
     */
    function sentTeamTokens(address _to) private onlyOwner isNotWork {
        //Снимаем с кошельков нужную сумму. На остаток даже
        // не смотрим - отправка токенов команде идёт в самом начале, 
        //и затронет только 4 из 20 кошельков. Таким образом, тут
        //остаток всегда будет равено нолю
        removeTokens(teamWalletTokens);
        //Прибавляем к балансу получателя сумму платежа
        balances[_to] = balances[_to].add(teamWalletTokens);
    }

    /**
        @dev Добавляем транзакцию в обработку
        @param _to - адрес получателя транзакции
        @param cost - сумма транзакции в токенах
        @param ident - идентификатор транзакции
     */     
    function addTransaction(address _to, uint cost, string ident) public onlyOwner isWork {
        //Если адрес получателя передан корректно
        if(_to != address(0)) {
            //Инициализируем транзакцию в памяти
            Transaction memory tr;
            tr._to = _to;
            tr.cost = cost;
            tr.sign = false;
            tr.create = true;
            //Получаем id транзакции из строки с идентификатором и
            //записываем информацию о транзакции
            transactions[keccak256(abi.encodePacked((ident)))] = tr;
        }
    }

    /**
        @dev Подписываем транзакцию
        @param ident - идентификатор транзакции
        @return - часть суммы, на которую не хватило баланса кошелька
     */
    function signTransaction(string ident) public onlySigner isWork returns(uint) {
        //Записываем остаток, как 0
        uint remainder = 0;
        //Получаем id транзакции из строки с идентификатором 
        bytes32 id = keccak256(abi.encodePacked((ident)));
        //Если транзакция была создана
        if(transactions[id].create == true) {
            //Подписываем транзакцию
            transactions[id].sign = true;
            //Завершаем транзакцию, получив остаток, в случае его наличия
            remainder = completeTransaction(id);
        }
        //Возвращаем сумму остатка
        return remainder;
    }

    /**
        @dev завершаем проведение транзакции
        @param id - идентификатор транзакции
        @return - часть суммы, на которую не хватило баланса кошелька
     */
    function completeTransaction(bytes32 id) private onlySigner isWork returns(uint) {
        //Получаем сумму транзакции
        uint cost = transactions[id].cost;
        //Снимаем токены с кошельков
        uint remainder = removeTokens(cost);
        //Вычитаем остаток от суммы транзакции, из изначальной суммы
        transactions[id].cost -= remainder;
        //Прибавляем к балансу получателя сумму платежа
        balances[transactions[id]._to] = balances[transactions[id]._to].add(transactions[id].cost);
        //Возвращаем остаток
        return remainder;
    }
}


/**
    @dev Основной контракт токенов
 */
contract GGPCoin is MintableToken {
    //Список командных кошельков
    Team private teamWallets;

    //Флаг, показывающий, что трансферы разрешены
    bool private allowTransfer;
    //Название токена
    string public name = "GGPro Coin";
    //Символ токена
    string public symbol = "GGP";
    //Дробность (количество знаков, после запятой).
    uint public decimals = 5;
    //Время запуска основной фазы работы смартконтракта
    uint public startTime;
    //Флаг, показывающий, что разрешение на выполнение 
    //транзакций ждёт только подписи
    bool private allowTransfersWaitSign;

    /**
        @dev Конструктор основного контракта токена
     */
    constructor() public {
        //инициализируем контракт команды
        teamWallets = new Team();
        //Указываем, что по дефолту транзакции отключены
        allowTransfer = false;
        //Указываем, что распоряжения, на активацию 
        //транзакций ещё не было
        allowTransfersWaitSign = false;
    }    


    /**
        @dev Очищает список возвратов пользователя
        @param _sender - адрес пользователя, для которого необходимо очистить список
     */
    function clearRefundsInfo(address _sender) public onlyOwner isWork {        
        //Получаем список возвратов пользователя
        RefundInfo[] memory ril = getRefundsInfo(_sender);
        //Проходимся по ним
        for(uint i = 0; i < ril.length; i++) {
            //Возвращаем токены от каждой обратно в кошельки
            returnTokens(ril[i].cost);
        }
        //Удаляем все возвраты
        clearRefunds(_sender);
    }

    /**
    * @dev Позволяет кому угодно передавать токены, после начала торгов
    * @param _to Адрес получателя токенов
    * @param _value КОличество передаваемых токенов
    */
    function transfer(address _to, uint _value) public isWork {         
        //проверяем, разрешён ли перевод, для данного адреса
        if (isAllowTransfer(msg.sender)) {
            //Если адрес получателя - это адрес возврата токенов
            if(isRefund(_to)) {
                //Добавляем данную транзакцию, в список возвратов
                addRefund(msg.sender, _value);
                //Списываем бабки со счёта отправителя
                remove(_to, _value);
            //Если адрес получателя другой
            } else {
                //Вызывает функцию transfer от basicToken. По сути у нас получилась обёртка.
                super.transfer(_to, _value);        
            }
            
        } else {
            //В противном случае - возвращаем ошибку
            require(false);
        }
    }

    /**
    * @dev Позволяет кому угодно отправлять токены, от имени _from
    * @param _from адрес, от чьего имени будут отправлены токены
    * @param _to Адрес, кому будут отправлены токены
    * @param _value сумма токенов, для отправки
    */
    function transferFrom(address _from, address _to, uint _value) public isWork { 
        //проверяем, разрешён ли перевод, для данного адреса
        if (isAllowTransfer(msg.sender)) {
            //Если адрес получателя - это адрес возврата токенов
            if(isRefund(_to)) {
                //Добавляем данную транзакцию, в список возвратов
                addRefund(msg.sender, _value);     
                //Снимаем бабки со счёта отправителя
                removeFrom(_from, _to, _value);
            //Если адрес получателя другой
            } else {
                //Вызывает функцию transferFrom от StandardToken (как я понял). По сути у нас получилась обёртка.
                super.transferFrom(_from, _to, _value);    
            } 
        } else {
            //В противном случае - возвращаем ошибку
            require(false);
        }
    }    

    
    /**
        @dev проверяем, разрешён ли перевод, для данного адреса
     */
    function isAllowTransfer(address sender) internal view returns (bool) {
        //Если разрешён перевод токенов в общем и целом, 
        //И, если аккаунт отправителя является командным - 
        //проверяем разрешение на перевод и у него.
        return (allowTransfer && teamWallets.isTeamAllow(sender));
    } 

    /**
        @dev Добавляем адрес, в список командных кошельков
        @param newAddress - адрес нового командного кошелька
     */
    function addTeamAddress(address newAddress) public onlyOwner isNotWork {
        //Добавляем адрес нового аккаунта в список команды
        teamWallets.addTeamAccount(newAddress);
    }

    /**
        @dev Переводим токены, на кошельки команды 
     */
    function sendTokensToTeam() public onlyOwner isNotWork {
        //Отправляем все кошельки команды, для перевода на них токенов
        setTeamTokens(teamWallets.getTeamAccounts());
    }
    
    /**
        @dev запуск работы смартконтракта
     */
    function startWork() public onlyOwner isNotWork {
        //Запускаем работу
        work = true;
        //Записываем, когда была запущена работа
        startTime = now;
    }

    /**
        @dev Активируем флаг ожидания подписи, на активацию транзакций
     */
    function allowTransactions() public onlyOwner isWork {
        allowTransfersWaitSign = true;
    }

    /**
        @dev Подписываем разрешение, на активацию транзакций
     */
    function signAllowTransactions() public onlySigner isWork {
        //Если разрашение транзакций ждёт подписи
        if(allowTransfersWaitSign == true) {
            //Разрашаем транзакции
            allowTransfer = true;
            //Говорим, что подпись поставлена
            allowTransfersWaitSign = false;
        } else {
            //Возвращаем ошибку
            require(false);
        }
    }
    
    /**
        @dev Активируем транзакции, для командных кошельков
     */
    function allowTeamTransactions() public onlyOwner isWork {
        //Проверяем время, прошедшее с момента запуска 
        //работы. Ожидание - 6 месяцев. Для автоматизации
        //этого процесса, всё реализовано специфично. 
        //При запуске работы запоминается время блока, в
        //формате метки времени, а для проверки берётся 
        //разница между текущим временем, и временем старта,  
        //и сравнивается с 6 * 30 * 24 * 60 * 60 = 15552000
        //(6 месяцев в секундах). Понятно, что длинна месяца 
        //разная, но погрешность в 4-5 дней я считаю не особо
        // существенной, для такого промежутка времени.
        //В случае чего, просто прибавлю к этому числу 
        // 60 * 60 * 24 * 5 = 432000 (количество секунд в 5 днях)
        uint waitTime = startTime - now;
        if(waitTime >= 15552000) {
            //Разрешаем командные транзакции
            teamWallets.allowTeamTransfers();
        } else {
            //В противном случае выводим ошибку
            require(false);
        }
    }
}



/**
    @title MainSale 
    @dev Основной контракт
 */
contract MainSale is Ownable {
    //Экземпляр контракта токена
    GGPCoin public token;

    /**
        @dev Конструктор главного рабочего контракта
     */
    constructor() public {
        //Инициализируем токен
        token = new GGPCoin();
        //Передаём управление токеном владельцу данного контракта
        token.transferOwnership(msg.sender);
    }

}