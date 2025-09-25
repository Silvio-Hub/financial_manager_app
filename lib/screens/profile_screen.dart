import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_widget.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar dados do usuário ao inicializar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserFromLocal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Perfil',
        showBackButton: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const LoadingWidget(message: 'Carregando perfil...');
          }

          if (userProvider.error != null) {
            return _buildErrorState(userProvider.error!);
          }

          final user = userProvider.user;
          
          if (user.isEmpty) {
            return _buildEmptyState();
          }

          return _buildProfileContent(user, userProvider);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditProfile(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar perfil',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<UserProvider>().loadUserFromLocal();
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Perfil não encontrado',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure seu perfil para começar',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _navigateToEditProfile(),
            child: const Text('Criar Perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(User user, UserProvider userProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(user, userProvider),
          const SizedBox(height: 24),
          _buildProfileStats(userProvider),
          const SizedBox(height: 24),
          _buildProfileDetails(user),
          const SizedBox(height: 80), // Espaço para o FAB
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User user, UserProvider userProvider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileImage(user),
            const SizedBox(height: 16),
            Text(
              user.name.isNotEmpty ? user.name : 'Nome não informado',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (user.occupation != null && user.occupation!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user.occupation!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(User user) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null
              ? Text(
                  user.initials,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStats(UserProvider userProvider) {
    final stats = userProvider.userStats;
    final completeness = stats['profileCompleteness'] as int;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas do Perfil',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        value: completeness / 100,
                        backgroundColor: Colors.grey[300],
                        strokeWidth: 6,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completeness%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Completo',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem(
                        'Membro desde',
                        _formatDate(stats['memberSince'] as DateTime),
                      ),
                      const SizedBox(height: 8),
                      _buildStatItem(
                        'Última atualização',
                        _formatDate(stats['lastUpdate'] as DateTime),
                      ),
                      if (stats['age'] != null) ...[
                        const SizedBox(height: 8),
                        _buildStatItem(
                          'Idade',
                          '${stats['age']} anos',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails(User user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Pessoais',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
              Icons.phone,
              'Telefone',
              user.phone ?? 'Não informado',
            ),
            const Divider(),
            _buildDetailItem(
              Icons.cake,
              'Data de Nascimento',
              user.birthDate != null
                  ? _formatDate(user.birthDate!)
                  : 'Não informado',
            ),
            const Divider(),
            _buildDetailItem(
              Icons.work,
              'Profissão',
              user.occupation ?? 'Não informado',
            ),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const Divider(),
              _buildDetailItem(
                Icons.info,
                'Biografia',
                user.bio!,
                isMultiline: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: isMultiline ? null : 1,
                  overflow: isMultiline ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }
}